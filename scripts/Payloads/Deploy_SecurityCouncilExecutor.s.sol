// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console2} from 'forge-std/console2.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';

/**
 * @title Arc
 * @author BGD Labs
 * @notice deploys the V4 Security Council Executor on Arc, owned by the Security Council Safe.
 * @dev standalone on purpose: this Executor is not part of the Governance V3 deployment registry, so it
 * does not extend GovBaseScript and writes nothing to `deployments/`. The `executorLvl1` slot is reserved
 * for the DAO's own Executor, which Arc does not have yet.
 */
contract Arc is Script {
  uint256 internal constant ARC_CHAIN_ID = 5042;
  address internal constant SECURITY_COUNCIL_SAFE =
    0x187AAE17d4931310B3fc75743e7F16Bdc9eD77e9;

  function run() external {
    require(block.chainid == ARC_CHAIN_ID, 'SCRIPT_ONLY_RUNS_ON_ARC');

    vm.startBroadcast();

    address executor = address(new Executor());
    Ownable(executor).transferOwnership(SECURITY_COUNCIL_SAFE);
    require(
      Ownable(executor).owner() == SECURITY_COUNCIL_SAFE,
      'OWNERSHIP_NOT_TRANSFERRED'
    );

    vm.stopBroadcast();

    console2.log('SecurityCouncilExecutor deployed at', executor);
  }
}
