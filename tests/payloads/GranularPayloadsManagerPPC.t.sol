// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IPermissionedPayloadsController, PermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {GranularPayloadsManagerPPC} from '../../src/contracts/payloads/access-control/GranularPayloadsManagerPPC.sol';
import {IGranularPayloadsManagerPPC} from '../../src/contracts/payloads/interfaces/IGranularPayloadsManagerPPC.sol';
import {Executor, IExecutor} from '../../src/contracts/payloads/Executor.sol';

contract GranularPayloadsManagerPPCTest is Test {
  address public constant PAYLOADS_MANAGER_1 = address(222);
  address public constant PAYLOADS_MANAGER_2 = address(333);

  GranularPayloadsManagerPPC public granularManager;
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

    PermissionedPayloadsController ppcImpl = new PermissionedPayloadsController();

    address[] memory managers = new address[](2);
    managers[0] = PAYLOADS_MANAGER_1;
    managers[1] = PAYLOADS_MANAGER_2;

    // Deploy PPC
    ppc = IPermissionedPayloadsController(
      proxyFactory.create(
        address(ppcImpl),
        address(this),
        abi.encodeCall(
          IPermissionedPayloadsController.initialize,
          (
            address(executor),
            address(this), // guardian is test contract for setup
            address(this), // payload manager is test contract for setup
            executors
          )
        )
      )
    );

    // Deploy granularManager
    granularManager = new GranularPayloadsManagerPPC(
      executor,
      address(ppc),
      managers
    );

    // Update payloadsManager on PPC
    vm.prank(Ownable(address(ppc)).owner());
    ppc.updatePayloadsManager(address(granularManager));

    Ownable(address(executor)).transferOwnership(address(ppc));
  }

  // ---- createPayload tests ----

  function test_createPayload_withPayloadsManagerRole() public {
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
  }

  function test_createPayload_withSecondManager() public {
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_2);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
  }

  function test_createPayload_revertsForUnauthorized() public {
    address invalidCaller = address(444);
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = _buildActions();

    assertFalse(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), invalidCaller));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        granularManager.PAYLOADS_MANAGER_ROLE()
      )
    );
    vm.prank(invalidCaller);
    granularManager.createPayload(actions);
  }

  function test_createPayload_revertsForAdminWithoutManagerRole() public {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = _buildActions();

    assertFalse(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), executor));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        executor,
        granularManager.PAYLOADS_MANAGER_ROLE()
      )
    );
    vm.prank(executor);
    granularManager.createPayload(actions);
  }

  function test_createPayload_incrementsPayloadCount() public {
    uint40 countBefore = ppc.getPayloadsCount();
    _createPayload(PAYLOADS_MANAGER_1);
    assertEq(ppc.getPayloadsCount(), countBefore + 1);
  }

  // ---- cancelPayload tests ----

  function test_cancelPayload_withPayloadsManagerRole() public {
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    vm.prank(PAYLOADS_MANAGER_1);
    granularManager.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_withSecondManager() public {
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    vm.prank(PAYLOADS_MANAGER_2);
    granularManager.cancelPayload(payloadId);

    assertEq(
      uint8(ppc.getPayloadState(payloadId)),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
  }

  function test_cancelPayload_revertsForUnauthorized() public {
    address invalidCaller = address(444);
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertFalse(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), invalidCaller));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        granularManager.PAYLOADS_MANAGER_ROLE()
      )
    );
    vm.prank(invalidCaller);
    granularManager.cancelPayload(payloadId);
  }

  function test_cancelPayload_revertsForAdminWithoutManagerRole() public {
    uint40 payloadId = _createPayload(PAYLOADS_MANAGER_1);

    assertFalse(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), executor));
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        executor,
        granularManager.PAYLOADS_MANAGER_ROLE()
      )
    );
    vm.prank(executor);
    granularManager.cancelPayload(payloadId);
  }

  // ---- Role management tests ----

  function test_grantPayloadsManagerRole_byAdmin() public {
    address newManager = address(666);
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();

    vm.prank(executor);
    granularManager.grantRole(managerRole, newManager);

    assertTrue(granularManager.hasRole(managerRole, newManager));
  }

  function test_revokePayloadsManagerRole_byAdmin() public {
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();

    vm.prank(executor);
    granularManager.revokeRole(managerRole, PAYLOADS_MANAGER_1);

    assertFalse(granularManager.hasRole(managerRole, PAYLOADS_MANAGER_1));
  }

  function test_revokedManager_cannotCreatePayload() public {
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();

    vm.prank(executor);
    granularManager.revokeRole(managerRole, PAYLOADS_MANAGER_1);

    IPayloadsControllerCore.ExecutionAction[]
      memory actions = _buildActions();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        managerRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularManager.createPayload(actions);
  }

  function test_grantRole_revertsForNonAdmin() public {
    address invalidCaller = address(444);
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();
    bytes32 adminRole = granularManager.DEFAULT_ADMIN_ROLE();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        invalidCaller,
        adminRole
      )
    );
    vm.prank(invalidCaller);
    granularManager.grantRole(managerRole, address(999));
  }

  function test_grantPayloadsManagerRole_byPayloadsManagerRole() public {
    address newManager = address(888);
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();
    bytes32 adminRole = granularManager.DEFAULT_ADMIN_ROLE();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        adminRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularManager.grantRole(managerRole, newManager);
  }

  function test_revokePayloadsManagerRole_byPayloadsManagerRole() public {
    bytes32 managerRole = granularManager.PAYLOADS_MANAGER_ROLE();
    bytes32 adminRole = granularManager.DEFAULT_ADMIN_ROLE();

    assertTrue(granularManager.hasRole(managerRole, PAYLOADS_MANAGER_1));
    assertTrue(granularManager.hasRole(managerRole, PAYLOADS_MANAGER_2));

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        PAYLOADS_MANAGER_1,
        adminRole
      )
    );
    vm.prank(PAYLOADS_MANAGER_1);
    granularManager.revokeRole(managerRole, PAYLOADS_MANAGER_2);
  }

  function test_getRoleMembers_returnsAllManagers() public view {
    assertEq(granularManager.getRoleMemberCount(granularManager.PAYLOADS_MANAGER_ROLE()), 2);
    assertEq(granularManager.getRoleMember(granularManager.PAYLOADS_MANAGER_ROLE(), 0), PAYLOADS_MANAGER_1);
    assertEq(granularManager.getRoleMember(granularManager.PAYLOADS_MANAGER_ROLE(), 1), PAYLOADS_MANAGER_2);
  }

  // ---- Constructor tests ----

  function test_constructor_revertsOnZeroGovernanceExecutor() public {
    address[] memory managers = new address[](1);
    managers[0] = PAYLOADS_MANAGER_1;

    vm.expectRevert(IGranularPayloadsManagerPPC.InvalidZeroAddress.selector);
    new GranularPayloadsManagerPPC(address(0), address(ppc), managers);
  }

  function test_constructor_revertsOnZeroPayloadsController() public {
    address[] memory managers = new address[](1);
    managers[0] = PAYLOADS_MANAGER_1;

    vm.expectRevert(IGranularPayloadsManagerPPC.InvalidZeroAddress.selector);
    new GranularPayloadsManagerPPC(executor, address(0), managers);
  }

  function test_constructor_revertsOnZeroAddressInManagers() public {
    address[] memory managers = new address[](2);
    managers[0] = PAYLOADS_MANAGER_1;
    managers[1] = address(0);

    vm.expectRevert(IGranularPayloadsManagerPPC.InvalidZeroAddress.selector);
    new GranularPayloadsManagerPPC(executor, address(ppc), managers);
  }

  function test_constructor_setsRolesCorrectly() public view {
    assertTrue(granularManager.hasRole(granularManager.DEFAULT_ADMIN_ROLE(), executor));
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_1));
    assertTrue(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), PAYLOADS_MANAGER_2));
    assertFalse(granularManager.hasRole(granularManager.PAYLOADS_MANAGER_ROLE(), address(444))); // invalid address
  }

  function test_constructor_setsPayloadsController() public view {
    assertEq(address(granularManager.PAYLOADS_CONTROLLER()), address(ppc));
  }

  function test_constructor_emptyManagersArray() public {
    address[] memory managers = new address[](0);
    GranularPayloadsManagerPPC manager = new GranularPayloadsManagerPPC(
      executor,
      address(ppc),
      managers
    );
    assertEq(manager.getRoleMemberCount(manager.PAYLOADS_MANAGER_ROLE()), 0);
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
    IPayloadsControllerCore.ExecutionAction[] memory actions = _buildActions();
    vm.prank(caller);
    return granularManager.createPayload(actions);
  }
}
