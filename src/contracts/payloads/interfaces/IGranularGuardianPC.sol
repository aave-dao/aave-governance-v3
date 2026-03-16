// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';

/**
 * @title IGranularGuardianPC
 * @author BGD Labs
 * @notice Interface for the GranularGuardianPC contract
 */
interface IGranularGuardianPC {
  /**
   * @notice Thrown when a zero address is provided where it is not allowed
   */
  error InvalidZeroAddress();

  /**
   * @notice Returns the role identifier for the cancellation role
   * @return bytes32 role identifier
   */
  function CANCELLATION_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the address of the PayloadsController this contract guards
   * @return IPayloadsControllerCore interface of the PayloadsController
   */
  function PAYLOADS_CONTROLLER() external view returns (IPayloadsControllerCore);

  /**
   * @notice Cancels a payload on the PayloadsController
   * @dev Only callable by addresses with CANCELLATION_ROLE
   * @param payloadId id of the payload to cancel
   */
  function cancelPayload(uint40 payloadId) external;

  /**
   * @notice Updates the guardian address on the PayloadsController
   * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
   * @param newGuardian new guardian address to set on the PayloadsController
   */
  function updateGuardian(address newGuardian) external;
}
