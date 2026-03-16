// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IWithGuardian} from 'aave-delivery-infrastructure/contracts/old-oz/interfaces/IWithGuardian.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {PayloadsController} from '../../src/contracts/payloads/PayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {GranularGuardianPC} from '../../src/contracts/payloads/access-control/GranularGuardianPC.sol';
import {IGranularGuardianPC} from '../../src/contracts/payloads/interfaces/IGranularGuardianPC.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';

contract GranularGuardianPCTest is Test {
  address public constant CANCELLER_1 = address(222);
  address public constant CANCELLER_2 = address(333);

  GranularGuardianPC public granularGuardian;
  IPayloadsControllerCore public pc;
  address public executor;

  function setUp() public {
    executor = address(new Executor());
    TransparentProxyFactory proxyFactory = new TransparentProxyFactory();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: executor
      })
    });

    PayloadsController pcImpl = new PayloadsController(
      address(0x6666), // cross chain controller (arbitrary for tests)
      address(0x7777), // message originator (arbitrary for tests)
      1 // origin chain id
    );

    // Deploy PC with address(this) as guardian so setUp can call updateGuardian directly
    pc = IPayloadsControllerCore(
      proxyFactory.create(
        address(pcImpl),
        address(this),
        abi.encodeCall(
          IPayloadsControllerCore.initialize,
          (
            address(this), // owner
            address(this), // test contract is initial guardian
            executors
          )
        )
      )
    );

    address[] memory cancellers = new address[](2);
    cancellers[0] = CANCELLER_1;
    cancellers[1] = CANCELLER_2;

    granularGuardian = new GranularGuardianPC(
      executor,
      address(pc),
      cancellers
    );

    // Update PC guardian to granularGuardian (test contract is current guardian)
    IWithGuardian(address(pc)).updateGuardian(address(granularGuardian));

    Ownable(executor).transferOwnership(address(pc));
  }

  // ---- cancelPayload tests ----

  function test_cancelPayload_withCancellationRole() public {
    uint40 payloadId = _createPayload();

    vm.prank(CANCELLER_1);
    granularGuardian.cancelPayload(payloadId);

    assertEq(
      uint8(pc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_withSecondCanceller() public {
    uint40 payloadId = _createPayload();

    vm.prank(CANCELLER_2);
    granularGuardian.cancelPayload(payloadId);

    assertEq(
      uint8(pc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_revertsForUnauthorized() public {
    address invalidCaller = address(444);
    uint40 payloadId = _createPayload();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        granularGuardian.CANCELLATION_ROLE()
      )
    );
    vm.prank(invalidCaller);
    granularGuardian.cancelPayload(payloadId);
  }

  function test_cancelPayload_revertsForAdminWithoutCancellationRole() public {
    uint40 payloadId = _createPayload();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        executor,
        granularGuardian.CANCELLATION_ROLE()
      )
    );
    vm.prank(executor);
    granularGuardian.cancelPayload(payloadId);
  }

  // ---- updateGuardian tests ----

  function test_updateGuardian_withAdminRole() public {
    address newGuardian = address(555);
    vm.prank(executor);
    granularGuardian.updateGuardian(newGuardian);

    assertEq(IWithGuardian(address(pc)).guardian(), newGuardian);
  }

  function test_updateGuardian_revertsForUnauthorized() public {
    address invalidCaller = address(444);
    address newGuardian = address(555);
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        granularGuardian.DEFAULT_ADMIN_ROLE()
      )
    );
    vm.prank(invalidCaller);
    granularGuardian.updateGuardian(newGuardian);
  }

  function test_updateGuardian_revertsForCancellerWithoutAdminRole() public {
    address newGuardian = address(555);
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        granularGuardian.DEFAULT_ADMIN_ROLE()
      )
    );
    vm.prank(CANCELLER_1);
    granularGuardian.updateGuardian(newGuardian);
  }

  // ---- Role management tests ----

  function test_grantCancellationRole_byAdmin() public {
    address newCanceller = address(0x8888);
    bytes32 cancellationRole = granularGuardian.CANCELLATION_ROLE();

    vm.prank(executor);
    granularGuardian.grantRole(cancellationRole, newCanceller);

    assertTrue(granularGuardian.hasRole(cancellationRole, newCanceller));
  }

  function test_grantCancellationRole_byCancellationRole() public {
    address newCanceller = address(888);
    bytes32 cancellationRole = granularGuardian.CANCELLATION_ROLE();
    bytes32 adminRole = granularGuardian.DEFAULT_ADMIN_ROLE();

    assertTrue(granularGuardian.hasRole(cancellationRole, CANCELLER_1));

    vm.prank(CANCELLER_1);
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        adminRole
      )
    );
    granularGuardian.grantRole(cancellationRole, newCanceller);
  }

  function test_revokeCancellationRole_byCancellationRole() public {
    bytes32 cancellationRole = granularGuardian.CANCELLATION_ROLE();
    bytes32 adminRole = granularGuardian.DEFAULT_ADMIN_ROLE();

    assertTrue(granularGuardian.hasRole(cancellationRole, CANCELLER_1));
    assertTrue(granularGuardian.hasRole(cancellationRole, CANCELLER_2));

    vm.prank(CANCELLER_1);
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        adminRole
      )
    );
    granularGuardian.revokeRole(cancellationRole, CANCELLER_2);
  }

  function test_revokeCancellationRole_byAdmin() public {
    bytes32 cancellationRole = granularGuardian.CANCELLATION_ROLE();

    vm.prank(executor);
    granularGuardian.revokeRole(cancellationRole, CANCELLER_1);

    assertFalse(granularGuardian.hasRole(cancellationRole, CANCELLER_1));
  }

  function test_grantRole_revertsForNonAdmin() public {
    address invalidCaller = address(444);
    bytes32 cancellationRole = granularGuardian.CANCELLATION_ROLE();
    bytes32 adminRole = granularGuardian.DEFAULT_ADMIN_ROLE();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        adminRole
      )
    );
    vm.prank(invalidCaller);
    granularGuardian.grantRole(cancellationRole, address(0x9999));
  }

  function test_getRoleMembers_returnsAllCancellers() public view {
    assertEq(granularGuardian.getRoleMemberCount(granularGuardian.CANCELLATION_ROLE()), 2);
    assertEq(granularGuardian.getRoleMember(granularGuardian.CANCELLATION_ROLE(), 0), CANCELLER_1);
    assertEq(granularGuardian.getRoleMember(granularGuardian.CANCELLATION_ROLE(), 1), CANCELLER_2);
  }

  // ---- Constructor tests ----

  function test_constructor_revertsOnZeroGovernanceExecutor() public {
    address[] memory cancellers = new address[](1);
    cancellers[0] = CANCELLER_1;

    vm.expectRevert(IGranularGuardianPC.InvalidZeroAddress.selector);
    new GranularGuardianPC(address(0), address(pc), cancellers);
  }

  function test_constructor_revertsOnZeroPayloadsController() public {
    address[] memory cancellers = new address[](1);
    cancellers[0] = CANCELLER_1;

    vm.expectRevert(IGranularGuardianPC.InvalidZeroAddress.selector);
    new GranularGuardianPC(executor, address(0), cancellers);
  }

  function test_constructor_revertsOnZeroAddressInCancellers() public {
    address[] memory cancellers = new address[](2);
    cancellers[0] = CANCELLER_1;
    cancellers[1] = address(0);

    vm.expectRevert(IGranularGuardianPC.InvalidZeroAddress.selector);
    new GranularGuardianPC(executor, address(pc), cancellers);
  }

  function test_constructor_setsRolesCorrectly() public view {
    address invalidCaller = address(444);
    assertTrue(granularGuardian.hasRole(granularGuardian.DEFAULT_ADMIN_ROLE(), executor));
    assertTrue(granularGuardian.hasRole(granularGuardian.CANCELLATION_ROLE(), CANCELLER_1));
    assertTrue(granularGuardian.hasRole(granularGuardian.CANCELLATION_ROLE(), CANCELLER_2));
    assertFalse(granularGuardian.hasRole(granularGuardian.CANCELLATION_ROLE(), invalidCaller));
  }

  function test_constructor_setsPayloadsController() public view {
    assertEq(address(granularGuardian.PAYLOADS_CONTROLLER()), address(pc));
  }

  function test_constructor_emptyCancellersArray() public {
    address[] memory cancellers = new address[](0);
    GranularGuardianPC guardian = new GranularGuardianPC(
      executor,
      address(pc),
      cancellers
    );
    assertEq(guardian.getRoleMemberCount(guardian.CANCELLATION_ROLE()), 0);
  }

  // ---- Helpers ----

  function _createPayload() internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = address(123);
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    // createPayload is open to anyone on PayloadsControllerCore
    return pc.createPayload(actions);
  }
}
