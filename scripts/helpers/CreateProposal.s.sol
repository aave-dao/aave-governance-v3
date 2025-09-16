// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import '../../src/interfaces/IGovernanceCore.sol';

abstract contract BaseCreateProposal is GovBaseScript {
  function getPayloads()
    public
    view
    virtual
    returns (PayloadsControllerUtils.Payload[] memory);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    bytes32 ipfsHash = bytes32(abi.encode(''));
    uint256 proposalId = IGovernanceCore(
      0x2B2fa1A67964613F8056FB8612494893A2B90DCa
    ).createProposal(getPayloads(), addresses.votingPortal_Eth_Pol, ipfsHash);

    console.log('proposalId', proposalId);
  }
}
