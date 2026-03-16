// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from 'forge-std/console.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {GranularGuardianPC} from '../../src/contracts/payloads/access-control/GranularGuardianPC.sol';
import {GranularPayloadsManagerPPC} from '../../src/contracts/payloads/access-control/GranularPayloadsManagerPPC.sol';
import '../GovBaseScript.sol';

abstract contract BaseDeployGranularPPCAccessControl is GovBaseScript {
  /**
   * @notice Returns the address to be granted DEFAULT_ADMIN_ROLE on both new contracts.
   *         Defaults to executorLvl1, the governance executor on the target network.
   */
  function GOVERNANCE_EXECUTOR() public view virtual returns (address) {
    return _getAddresses(TRANSACTION_NETWORK()).executorLvl1;
  }

  /**
   * @notice Returns the PermissionedPayloadsController address that GranularPayloadsManagerPPC / GranularGuardianPC will manage.
   */
  function PERMISSIONED_PAYLOADS_CONTROLLER() public view virtual returns (address);

  /**
   * @notice Returns the initial set of addresses to be granted CANCELLATION_ROLE
   *         on GranularGuardianPC at deployment.
   */
  function INITIAL_CANCELLATION_ROLE_HOLDERS()
    public
    view
    virtual
    returns (address[] memory);

  /**
   * @notice Returns the initial set of addresses to be granted PAYLOADS_MANAGER_ROLE
   *         on GranularPayloadsManagerPPC at deployment.
   */
  function INITIAL_PAYLOADS_MANAGER_ROLE_HOLDERS()
    public
    view
    virtual
    returns (address[] memory);

  function _execute(GovDeployerHelpers.Addresses memory) internal override {
    // --- Deploy GranularGuardianPC ---
    // Set this contract as the guardian on the target PayloadsController via updateGuardian().
    GranularGuardianPC granularGuardian = new GranularGuardianPC(
      GOVERNANCE_EXECUTOR(),
      PERMISSIONED_PAYLOADS_CONTROLLER(),
      INITIAL_CANCELLATION_ROLE_HOLDERS()
    );

    // --- Deploy GranularPayloadsManagerPPC ---
    // Set this contract as the payloadsManager on the target PermissionedPayloadsController
    // via updatePayloadsManager().
    GranularPayloadsManagerPPC granularPayloadsManager = new GranularPayloadsManagerPPC(
      GOVERNANCE_EXECUTOR(),
      PERMISSIONED_PAYLOADS_CONTROLLER(),
      INITIAL_PAYLOADS_MANAGER_ROLE_HOLDERS()
    );

    console.log('GranularGuardianPC:         ', address(granularGuardian));
    console.log('GranularPayloadsManagerPPC: ', address(granularPayloadsManager));
  }
}

contract Ethereum is BaseDeployGranularPPCAccessControl {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function PERMISSIONED_PAYLOADS_CONTROLLER() public pure override returns (address) {
    // TODO: replace with the actual PermissionedPayloadsController
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
