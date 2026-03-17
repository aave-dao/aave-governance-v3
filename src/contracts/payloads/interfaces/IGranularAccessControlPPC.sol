// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';

/**
 * @title IGranularAccessControlPPC
 * @author BGD Labs
 * @notice Interface for the GranularAccessControlPPC contract
 */
interface IGranularAccessControlPPC {
  /**
   * @notice Thrown when a zero address is provided where it is not allowed
   */
  error InvalidZeroAddress();

  /**
   * @notice Thrown when cancelPayload is called by an address that holds neither
   *         CANCELLATION_ROLE nor PAYLOADS_MANAGER_ROLE
   */
  error NotCancellerOrPayloadsManager();

  /**
   * @notice Returns the role identifier for the cancellation role
   * @return bytes32 role identifier
   */
  function CANCELLATION_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the role identifier for the payloads manager role
   * @return bytes32 role identifier
   */
  function PAYLOADS_MANAGER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the PermissionedPayloadsController this contract manages
   * @return IPayloadsControllerCore interface of the PermissionedPayloadsController
   */
  function PERMISSIONED_PAYLOADS_CONTROLLER() external view returns (IPayloadsControllerCore);

  /**
   * @notice Creates a payload on the PermissionedPayloadsController
   * @dev Only callable by addresses with PAYLOADS_MANAGER_ROLE
   * @param actions array of actions which this payload will contain
   * @return id of the created payload
   */
  function createPayload(
    IPayloadsControllerCore.ExecutionAction[] calldata actions
  ) external returns (uint40);

  /**
   * @notice Cancels a payload on the controller
   * @dev Callable by addresses with either CANCELLATION_ROLE or PAYLOADS_MANAGER_ROLE
   * @param payloadId id of the payload to cancel
   */
  function cancelPayload(uint40 payloadId) external;

  /**
   * @notice Updates the guardian address on the underlying PayloadsController
   * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
   * @param newGuardian new guardian address to set on the controller
   */
  function updateGuardian(address newGuardian) external;
}
