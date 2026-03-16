// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlEnumerable} from 'openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {IPayloadsControllerCore} from '../interfaces/IPayloadsControllerCore.sol';
import {IGranularGuardianPC} from '../interfaces/IGranularGuardianPC.sol';

/**
 * @title GranularGuardianPC
 * @author BGD Labs
 * @notice Contract to granularize the guardian role on PayloadsController.
 *         This contract is intended to be set as the guardian on a PayloadsController instance,
 *         allowing multiple addresses to hold cancellation permissions rather than a single guardian.
 * @dev DEFAULT_ADMIN_ROLE holders can update the guardian address on the target PayloadsController, should be given to the governance executor.
 * @dev CANCELLATION_ROLE holders can call cancelPayload on the target PayloadsController.
 */
contract GranularGuardianPC is AccessControlEnumerable, IGranularGuardianPC {
  /// @inheritdoc IGranularGuardianPC
  bytes32 public constant CANCELLATION_ROLE = keccak256('CANCELLATION_ROLE');

  /// @inheritdoc IGranularGuardianPC
  IPayloadsControllerCore public immutable PAYLOADS_CONTROLLER;

  /**
   * @notice Constructor
   * @param governanceExecutor address to be granted DEFAULT_ADMIN_ROLE (governance executor)
   * @param payloadsController address of the PayloadsController this contract guards
   * @param cancellationRoleAddresses initial addresses to be granted CANCELLATION_ROLE
   */
  constructor(
    address governanceExecutor,
    address payloadsController,
    address[] memory cancellationRoleAddresses
  ) {
    if (governanceExecutor == address(0)) revert InvalidZeroAddress();
    if (payloadsController == address(0)) revert InvalidZeroAddress();

    _grantRole(DEFAULT_ADMIN_ROLE, governanceExecutor);
    PAYLOADS_CONTROLLER = IPayloadsControllerCore(payloadsController);

    for (uint256 i = 0; i < cancellationRoleAddresses.length; i++) {
      if (cancellationRoleAddresses[i] == address(0)) revert InvalidZeroAddress();
      _grantRole(CANCELLATION_ROLE, cancellationRoleAddresses[i]);
    }
  }

  /// @inheritdoc IGranularGuardianPC
  function cancelPayload(uint40 payloadId) external onlyRole(CANCELLATION_ROLE) {
    PAYLOADS_CONTROLLER.cancelPayload(payloadId);
  }

  /// @inheritdoc IGranularGuardianPC
  function updateGuardian(address newGuardian) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IWithGuardian(address(PAYLOADS_CONTROLLER)).updateGuardian(newGuardian);
  }
}
