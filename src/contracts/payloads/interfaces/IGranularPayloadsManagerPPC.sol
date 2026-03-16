// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';

/**
 * @title IGranularPayloadsManagerPPC
 * @author BGD Labs
 * @notice Interface for the GranularPayloadsManagerPPC contract
 */
interface IGranularPayloadsManagerPPC {
  /**
   * @notice Thrown when a zero address is provided where it is not allowed
   */
  error InvalidZeroAddress();

  /**
   * @notice Returns the role identifier for the payloads manager role
   * @return bytes32 role identifier
   */
  function PAYLOADS_MANAGER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the PermissionedPayloadsController this contract manages
   * @return IPayloadsControllerCore interface of the PermissionedPayloadsController
   */
  function PAYLOADS_CONTROLLER() external view returns (IPayloadsControllerCore);

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
   * @notice Cancels a payload on the PermissionedPayloadsController
   * @dev Only callable by addresses with PAYLOADS_MANAGER_ROLE
   * @param payloadId id of the payload to cancel
   */
  function cancelPayload(uint40 payloadId) external;
}
