// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from 'forge-std/console.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {GranularAccessControlPPC} from '../../src/contracts/payloads/access-control/GranularAccessControlPPC.sol';
import '../GovBaseScript.sol';

abstract contract BaseDeployGranularPPCAccessControl is GovBaseScript {
  /**
   * @notice Returns the address to be granted DEFAULT_ADMIN_ROLE on the new contract.
   *         Defaults to executorLvl1, the governance executor on the target network.
   */
  function GOVERNANCE_EXECUTOR() public view virtual returns (address) {
    return _getAddresses(TRANSACTION_NETWORK()).executorLvl1;
  }

  /**
   * @notice Returns the PermissionedPayloadsController address that GranularAccessControlPPC will manage.
   */
  function PERMISSIONED_PAYLOADS_CONTROLLER() public view virtual returns (address);

  /**
   * @notice Returns the initial set of addresses to be granted CANCELLATION_ROLE at deployment.
   */
  function INITIAL_CANCELLATION_ROLE_HOLDERS()
    public
    view
    virtual
    returns (address[] memory);

  /**
   * @notice Returns the initial set of addresses to be granted PAYLOADS_MANAGER_ROLE at deployment.
   */
  function INITIAL_PAYLOADS_MANAGER_ROLE_HOLDERS()
    public
    view
    virtual
    returns (address[] memory);

  function _execute(GovDeployerHelpers.Addresses memory) internal override {
    // Deploy GranularAccessControlPPC.
    // After deployment, set this contract as both the guardian and the payloadsManager on the
    // target controller by calling updateGuardian() and updatePayloadsManager() respectively.
    GranularAccessControlPPC granularAC = new GranularAccessControlPPC(
      GOVERNANCE_EXECUTOR(),
      PERMISSIONED_PAYLOADS_CONTROLLER(),
      INITIAL_CANCELLATION_ROLE_HOLDERS(),
      INITIAL_PAYLOADS_MANAGER_ROLE_HOLDERS()
    );

    console.log('GranularAccessControlPPC:', address(granularAC));
  }
}

contract Ethereum is BaseDeployGranularPPCAccessControl {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function PERMISSIONED_PAYLOADS_CONTROLLER() public pure override returns (address) {
    // TODO: replace with the actual target PayloadsController / PermissionedPayloadsController
    return address(666);
  }

  function INITIAL_CANCELLATION_ROLE_HOLDERS()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory holders = new address[](1);
    // TODO: replace with the actual initial CANCELLATION_ROLE holders (e.g. Security Council Safe)
    holders[0] = address(222);
    return holders;
  }

  function INITIAL_PAYLOADS_MANAGER_ROLE_HOLDERS()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory holders = new address[](1);
    // TODO: replace with the actual initial PAYLOADS_MANAGER_ROLE holders (e.g. Agent Contract addresses)
    holders[0] = address(333);
    return holders;
  }
}
