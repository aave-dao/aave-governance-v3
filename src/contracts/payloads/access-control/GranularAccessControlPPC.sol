// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControlEnumerable} from 'openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {IPayloadsControllerCore} from '../interfaces/IPayloadsControllerCore.sol';
import {IGranularAccessControlPPC} from '../interfaces/IGranularAccessControlPPC.sol';

/**
 * @title GranularAccessControlPPC
 * @author BGD Labs
 * @notice Contract to granularize both the guardian and payloads manager roles on a
 *         PermissionedPayloadsController instance. This contract is intended to be set as
 *         both the guardian and the payloads manager on the permissioned-payloads-controller, distributing
 *         those permissions across multiple independent addresses.
 * @dev DEFAULT_ADMIN_ROLE should be granted to the governance executor so that role
 *      management and updating guardian go through governance.
 * @dev PAYLOADS_MANAGER_ROLE holders can create and cancel payloads on the controller.
 * @dev CANCELLATION_ROLE holders can only cancel payloads on the controller.
 */
contract GranularAccessControlPPC is AccessControlEnumerable, IGranularAccessControlPPC {
  /// @inheritdoc IGranularAccessControlPPC
  bytes32 public constant CANCELLATION_ROLE = keccak256('CANCELLATION_ROLE');

  /// @inheritdoc IGranularAccessControlPPC
  bytes32 public constant PAYLOADS_MANAGER_ROLE = keccak256('PAYLOADS_MANAGER_ROLE');

  /// @inheritdoc IGranularAccessControlPPC
  IPayloadsControllerCore public immutable PERMISSIONED_PAYLOADS_CONTROLLER;

  modifier onlyCancellerOrPayloadsManager() {
    require(
      hasRole(CANCELLATION_ROLE, msg.sender) || hasRole(PAYLOADS_MANAGER_ROLE, msg.sender),
      NotCancellerOrPayloadsManager()
    );
    _;
  }

  /**
   * @notice Constructor
   * @param governanceExecutor address to be granted DEFAULT_ADMIN_ROLE
   * @param permissionedPayloadsController address of the PermissionedPayloadsController this contract manages
   * @param cancellationRoleAddresses initial addresses to be granted CANCELLATION_ROLE
   * @param payloadsManagerAddresses initial addresses to be granted PAYLOADS_MANAGER_ROLE
   */
  constructor(
    address governanceExecutor,
    address permissionedPayloadsController,
    address[] memory cancellationRoleAddresses,
    address[] memory payloadsManagerAddresses
  ) {
    require(governanceExecutor != address(0), InvalidZeroAddress());
    require(permissionedPayloadsController != address(0), InvalidZeroAddress());

    _grantRole(DEFAULT_ADMIN_ROLE, governanceExecutor);
    PERMISSIONED_PAYLOADS_CONTROLLER = IPayloadsControllerCore(permissionedPayloadsController);

    for (uint256 i = 0; i < cancellationRoleAddresses.length; i++) {
      require(cancellationRoleAddresses[i] != address(0), InvalidZeroAddress());
      _grantRole(CANCELLATION_ROLE, cancellationRoleAddresses[i]);
    }
    for (uint256 i = 0; i < payloadsManagerAddresses.length; i++) {
      require(payloadsManagerAddresses[i] != address(0), InvalidZeroAddress());
      _grantRole(PAYLOADS_MANAGER_ROLE, payloadsManagerAddresses[i]);
    }
  }

  /// @inheritdoc IGranularAccessControlPPC
  function createPayload(
    IPayloadsControllerCore.ExecutionAction[] calldata actions
  ) external onlyRole(PAYLOADS_MANAGER_ROLE) returns (uint40) {
    return PERMISSIONED_PAYLOADS_CONTROLLER.createPayload(actions);
  }

  /// @inheritdoc IGranularAccessControlPPC
  function cancelPayload(uint40 payloadId) external onlyCancellerOrPayloadsManager {
    PERMISSIONED_PAYLOADS_CONTROLLER.cancelPayload(payloadId);
  }

  /// @inheritdoc IGranularAccessControlPPC
  function updateGuardian(address newGuardian) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IWithGuardian(address(PERMISSIONED_PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}
