// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IWithGuardian} from 'aave-delivery-infrastructure/contracts/old-oz/interfaces/IWithGuardian.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IPermissionedPayloadsController, PermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {GranularAccessControlPPC} from '../../src/contracts/payloads/access-control/GranularAccessControlPPC.sol';
import {IGranularAccessControlPPC} from '../../src/contracts/payloads/interfaces/IGranularAccessControlPPC.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';

contract GranularAccessControlPPCTest is Test {
  address public constant CANCELLER_1 = address(222);
  address public constant CANCELLER_2 = address(333);
  address public constant PAYLOADS_MANAGER_1 = address(444);
  address public constant PAYLOADS_MANAGER_2 = address(555);

  GranularAccessControlPPC public granularAC;
  IPermissionedPayloadsController public ppc;
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

    // Deploy PPC with test contract as guardian and payloadsManager so setUp can migrate both
    ppc = IPermissionedPayloadsController(
      proxyFactory.create(
        address(new PermissionedPayloadsController()),
        address(this),
        abi.encodeCall(
          IPermissionedPayloadsController.initialize,
          (
            address(executor), // owner
            address(this),     // test contract is initial guardian
            address(this),     // test contract is initial payloadsManager
            executors
          )
        )
      )
    );

    address[] memory cancellers = new address[](2);
    cancellers[0] = CANCELLER_1;
    cancellers[1] = CANCELLER_2;

    address[] memory managers = new address[](2);
    managers[0] = PAYLOADS_MANAGER_1;
    managers[1] = PAYLOADS_MANAGER_2;

    granularAC = new GranularAccessControlPPC(executor, address(ppc), cancellers, managers);

    // Migrate guardian (test contract is current guardian, can call directly)
    IWithGuardian(address(ppc)).updateGuardian(address(granularAC));

    // Migrate payloadsManager (executor is PPC owner)
    vm.prank(address(executor));
    ppc.updatePayloadsManager(address(granularAC));

    Ownable(address(executor)).transferOwnership(address(ppc));
  }

  // ---- createPayload tests ----

  function test_createPayload_withPayloadsManagerRole() public {
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
  }

  function test_createPayload_withSecondPayloadsManager() public {
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_2);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
  }

  function test_createPayload_revertsForInvalidCaller() public {
    address invalidCaller = address(888);
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    assertFalse(granularAC.hasRole(managerRole, invalidCaller));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        managerRole
      )
    );
    vm.prank(invalidCaller);
    granularAC.createPayload(_buildActions());
  }

  function test_createPayload_revertsForAdminWithoutManagerRole() public {
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    assertFalse(granularAC.hasRole(managerRole, executor));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        executor,
        managerRole
      )
    );
    vm.prank(executor);
    granularAC.createPayload(_buildActions());
  }

  function test_createPayload_revertsForCancellationRoleHolder() public {
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_1));
    assertFalse(granularAC.hasRole(managerRole, CANCELLER_1));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        managerRole
      )
    );
    vm.prank(CANCELLER_1);
    granularAC.createPayload(_buildActions());
  }

  function test_createPayload_incrementsPayloadCount() public {
    uint40 countBefore = ppc.getPayloadsCount();
    _createPayload(PAYLOADS_MANAGER_1);
    assertEq(ppc.getPayloadsCount(), countBefore + 1);
  }

  // ---- cancelPayload tests ----

  function test_cancelPayload_withCancellationRole() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);
    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_1));

    vm.prank(CANCELLER_1);
    granularAC.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_withSecondCanceller() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);
    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_2));

    vm.prank(CANCELLER_2);
    granularAC.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_withPayloadsManagerRole() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));

    vm.prank(PAYLOADS_MANAGER_1);
    granularAC.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_withSecondPayloadsManager() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));

    vm.prank(PAYLOADS_MANAGER_2);
    granularAC.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_revertsForInvalidCaller() public {
    address invalidCaller = address(888);
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertFalse(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), invalidCaller));
    assertFalse(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), invalidCaller));

    vm.expectRevert(IGranularAccessControlPPC.NotCancellerOrPayloadsManager.selector);
    vm.prank(invalidCaller);
    granularAC.cancelPayload(payloadId);
  }

  function test_cancelPayload_revertsForAdminWithoutEitherRole() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertFalse(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), executor));
    assertFalse(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), executor));

    vm.expectRevert(IGranularAccessControlPPC.NotCancellerOrPayloadsManager.selector);
    vm.prank(executor);
    granularAC.cancelPayload(payloadId);
  }

  // ---- updateGuardian tests ----

  function test_updateGuardian_withAdminRole() public {
    address newGuardian = address(777);
    vm.prank(executor);
    granularAC.updateGuardian(newGuardian);

    assertEq(IWithGuardian(address(ppc)).guardian(), newGuardian);
  }

  function test_updateGuardian_revertsForInvalidCaller() public {
    address invalidCaller = address(888);
    address newGuardian = address(777);
    bytes32 adminRole = granularAC.DEFAULT_ADMIN_ROLE();

    assertFalse(granularAC.hasRole(adminRole, invalidCaller));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        adminRole
      )
    );
    vm.prank(invalidCaller);
    granularAC.updateGuardian(newGuardian);
  }

  function test_updateGuardian_revertsForCancellationRoleHolder() public {
    address newGuardian = address(777);
    bytes32 adminRole = granularAC.DEFAULT_ADMIN_ROLE();

    assertFalse(granularAC.hasRole(adminRole, CANCELLER_1));
    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_1));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        adminRole
      )
    );
    vm.prank(CANCELLER_1);
    granularAC.updateGuardian(newGuardian);
  }

  function test_updateGuardian_revertsForPayloadsManagerRoleHolder() public {
    address newGuardian = address(777);
    bytes32 adminRole = granularAC.DEFAULT_ADMIN_ROLE();

    assertFalse(granularAC.hasRole(adminRole, PAYLOADS_MANAGER_1));
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        adminRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularAC.updateGuardian(newGuardian);
  }

  // ---- Role management tests ----

  function test_grantCancellationRole_byAdmin() public {
    address newCanceller = address(666);
    bytes32 cancellationRole = granularAC.CANCELLATION_ROLE();

    assertTrue(granularAC.hasRole(granularAC.DEFAULT_ADMIN_ROLE(), executor));
    assertFalse(granularAC.hasRole(cancellationRole, newCanceller));

    vm.prank(executor);
    granularAC.grantRole(cancellationRole, newCanceller);

    assertTrue(granularAC.hasRole(cancellationRole, newCanceller));
  }

  function test_revokeCancellationRole_byAdmin() public {
    bytes32 cancellationRole = granularAC.CANCELLATION_ROLE();

    assertTrue(granularAC.hasRole(granularAC.DEFAULT_ADMIN_ROLE(), executor));
    assertTrue(granularAC.hasRole(cancellationRole, CANCELLER_1));

    vm.prank(executor);
    granularAC.revokeRole(cancellationRole, CANCELLER_1);

    assertFalse(granularAC.hasRole(cancellationRole, CANCELLER_1));
  }

  function test_grantPayloadsManagerRole_byAdmin() public {
    address newManager = address(666);
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    assertTrue(granularAC.hasRole(granularAC.DEFAULT_ADMIN_ROLE(), executor));
    assertFalse(granularAC.hasRole(managerRole, newManager));

    vm.prank(executor);
    granularAC.grantRole(managerRole, newManager);

    assertTrue(granularAC.hasRole(managerRole, newManager));
  }

  function test_revokePayloadsManagerRole_byAdmin() public {
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    assertTrue(granularAC.hasRole(granularAC.DEFAULT_ADMIN_ROLE(), executor));
    assertTrue(granularAC.hasRole(managerRole, PAYLOADS_MANAGER_1));

    vm.prank(executor);
    granularAC.revokeRole(managerRole, PAYLOADS_MANAGER_1);

    assertFalse(granularAC.hasRole(managerRole, PAYLOADS_MANAGER_1));
  }

  function test_grantCancellationRole_byCancellationRoleHolder_reverts() public {
    address newCanceller = address(666);
    bytes32 cancellationRole = granularAC.CANCELLATION_ROLE();
    bytes32 adminRole = granularAC.DEFAULT_ADMIN_ROLE();

    assertTrue(granularAC.hasRole(cancellationRole, CANCELLER_1));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        CANCELLER_1,
        adminRole
      )
    );
    vm.prank(CANCELLER_1);
    granularAC.grantRole(cancellationRole, newCanceller);
  }

  function test_revokePayloadsManagerRole_byPayloadsManagerRoleHolder_reverts() public {
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();
    bytes32 adminRole = granularAC.DEFAULT_ADMIN_ROLE();

    assertTrue(granularAC.hasRole(managerRole, PAYLOADS_MANAGER_1));
    assertTrue(granularAC.hasRole(managerRole, PAYLOADS_MANAGER_2));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        adminRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularAC.revokeRole(managerRole, PAYLOADS_MANAGER_2);
  }

  function test_revokedManager_cannotCreatePayload() public {
    bytes32 managerRole = granularAC.PAYLOADS_MANAGER_ROLE();

    vm.prank(executor);
    granularAC.revokeRole(managerRole, PAYLOADS_MANAGER_1);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        managerRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularAC.createPayload(_buildActions());
  }

  function test_getRoleMembers_returnsAllCancellers() public view {
    assertEq(granularAC.getRoleMemberCount(granularAC.CANCELLATION_ROLE()), 2);
    assertEq(granularAC.getRoleMember(granularAC.CANCELLATION_ROLE(), 0), CANCELLER_1);
    assertEq(granularAC.getRoleMember(granularAC.CANCELLATION_ROLE(), 1), CANCELLER_2);
  }

  function test_getRoleMembers_returnsAllManagers() public view {
    assertEq(granularAC.getRoleMemberCount(granularAC.PAYLOADS_MANAGER_ROLE()), 2);
    assertEq(granularAC.getRoleMember(granularAC.PAYLOADS_MANAGER_ROLE(), 0), PAYLOADS_MANAGER_1);
    assertEq(granularAC.getRoleMember(granularAC.PAYLOADS_MANAGER_ROLE(), 1), PAYLOADS_MANAGER_2);
  }

  // ---- Constructor tests ----

  function test_constructor_revertsOnZeroGovernanceExecutor() public {
    address[] memory cancellers = new address[](1);
    cancellers[0] = CANCELLER_1;
    address[] memory managers = new address[](0);

    vm.expectRevert(IGranularAccessControlPPC.InvalidZeroAddress.selector);
    new GranularAccessControlPPC(address(0), address(ppc), cancellers, managers);
  }

  function test_constructor_revertsOnZeroPayloadsController() public {
    address[] memory cancellers = new address[](0);
    address[] memory managers = new address[](1);
    managers[0] = PAYLOADS_MANAGER_1;

    vm.expectRevert(IGranularAccessControlPPC.InvalidZeroAddress.selector);
    new GranularAccessControlPPC(executor, address(0), cancellers, managers);
  }

  function test_constructor_revertsOnZeroAddressInCancellers() public {
    address[] memory cancellers = new address[](2);
    cancellers[0] = CANCELLER_1;
    cancellers[1] = address(0);
    address[] memory managers = new address[](0);

    vm.expectRevert(IGranularAccessControlPPC.InvalidZeroAddress.selector);
    new GranularAccessControlPPC(executor, address(ppc), cancellers, managers);
  }

  function test_constructor_revertsOnZeroAddressInManagers() public {
    address[] memory cancellers = new address[](0);
    address[] memory managers = new address[](2);
    managers[0] = PAYLOADS_MANAGER_1;
    managers[1] = address(0);

    vm.expectRevert(IGranularAccessControlPPC.InvalidZeroAddress.selector);
    new GranularAccessControlPPC(executor, address(ppc), cancellers, managers);
  }

  function test_constructor_setsRolesCorrectly() public view {
    assertTrue(granularAC.hasRole(granularAC.DEFAULT_ADMIN_ROLE(), executor));
    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_1));
    assertTrue(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), CANCELLER_2));
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    assertTrue(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));
    assertFalse(granularAC.hasRole(granularAC.CANCELLATION_ROLE(), address(999))); // invalid address
    assertFalse(granularAC.hasRole(granularAC.PAYLOADS_MANAGER_ROLE(), address(999))); // invalid address
  }

  function test_constructor_setsPayloadsController() public view {
    assertEq(address(granularAC.PERMISSIONED_PAYLOADS_CONTROLLER()), address(ppc));
  }

  function test_constructor_emptyRoleArrays() public {
    address[] memory empty = new address[](0);
    GranularAccessControlPPC ac = new GranularAccessControlPPC(executor, address(ppc), empty, empty);
    assertEq(ac.getRoleMemberCount(ac.CANCELLATION_ROLE()), 0);
    assertEq(ac.getRoleMemberCount(ac.PAYLOADS_MANAGER_ROLE()), 0);
  }

  // ---- Helpers ----

  function _buildActions()
    internal
    pure
    returns (IPayloadsControllerCore.ExecutionAction[] memory)
  {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = address(123);
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;
    return actions;
  }

  function _createPayload(address caller) internal returns (uint40) {
    vm.prank(caller);
    return granularAC.createPayload(_buildActions());
  }
}
