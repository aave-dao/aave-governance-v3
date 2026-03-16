// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlEnumerable} from 'openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol';
import {IPayloadsControllerCore} from '../interfaces/IPayloadsControllerCore.sol';
import {IGranularPayloadsManagerPPC} from '../interfaces/IGranularPayloadsManagerPPC.sol';

/**
 * @title GranularPayloadsManagerPPC
 * @author BGD Labs
 * @notice Contract to granularize the payloads manager role on PermissionedPayloadsController.
 *         This contract is intended to be set as the payloads manager on a PermissionedPayloadsController
 *         instance, allowing multiple addresses to create and cancel payloads rather than a single manager.
 * @dev DEFAULT_ADMIN_ROLE should be given to the governance executor so governance can manage roles.
 * @dev PAYLOADS_MANAGER_ROLE holders can call createPayload and cancelPayload on the target
 *      PermissionedPayloadsController.
 */
contract GranularPayloadsManagerPPC is AccessControlEnumerable, IGranularPayloadsManagerPPC {
  /// @inheritdoc IGranularPayloadsManagerPPC
  bytes32 public constant PAYLOADS_MANAGER_ROLE = keccak256('PAYLOADS_MANAGER_ROLE');

  /// @inheritdoc IGranularPayloadsManagerPPC
  IPayloadsControllerCore public immutable PAYLOADS_CONTROLLER;

  /**
   * @notice Constructor
   * @param governanceExecutor address to be granted DEFAULT_ADMIN_ROLE (governance executor)
   * @param payloadsController address of the PermissionedPayloadsController this contract manages
   * @param payloadsManagerAddresses initial addresses to be granted PAYLOADS_MANAGER_ROLE
   */
  constructor(
    address governanceExecutor,
    address payloadsController,
    address[] memory payloadsManagerAddresses
  ) {
    if (governanceExecutor == address(0)) revert InvalidZeroAddress();
    if (payloadsController == address(0)) revert InvalidZeroAddress();

    _grantRole(DEFAULT_ADMIN_ROLE, governanceExecutor);
    PAYLOADS_CONTROLLER = IPayloadsControllerCore(payloadsController);

    for (uint256 i = 0; i < payloadsManagerAddresses.length; i++) {
      if (payloadsManagerAddresses[i] == address(0)) revert InvalidZeroAddress();
      _grantRole(PAYLOADS_MANAGER_ROLE, payloadsManagerAddresses[i]);
    }
  }

  /// @inheritdoc IGranularPayloadsManagerPPC
  function createPayload(
    IPayloadsControllerCore.ExecutionAction[] calldata actions
  ) external onlyRole(PAYLOADS_MANAGER_ROLE) returns (uint40) {
    return PAYLOADS_CONTROLLER.createPayload(actions);
  }

  /// @inheritdoc IGranularPayloadsManagerPPC
  function cancelPayload(uint40 payloadId) external onlyRole(PAYLOADS_MANAGER_ROLE) {
    PAYLOADS_CONTROLLER.cancelPayload(payloadId);
  }
}
