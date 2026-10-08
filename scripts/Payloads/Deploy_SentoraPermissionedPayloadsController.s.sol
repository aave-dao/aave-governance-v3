// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {PermissionedPayloadsController, PayloadsControllerUtils, IPayloadsControllerCore} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import 'forge-std/Script.sol';

/**
 * @notice deploys a PermissionedPayloadsController and its Executor for Sentora on Ethereum.
 * @dev the addresses are not persisted in deployments/, as ethereum.json already tracks the existing permissioned
 *      payloads controller. They are read from the broadcast logs.
 * @dev the controller owner and its proxy admin owner are the governance Executor Lvl1, so only governance can
 *      change the execution delay or upgrade the controller.
 */
contract Ethereum is Script {
  // Sentora Operator Safe
  address internal constant PAYLOADS_MANAGER =
    0x6748f83C1d1F49Dffb715078B68180536aE7F40F;

  uint40 internal constant EXECUTION_DELAY = 2 days;

  function run() external {
    require(block.chainid == ChainIds.ETHEREUM, 'WRONG_NETWORK');

    vm.startBroadcast();
    Executor executor = new Executor();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        executor: address(executor),
        delay: EXECUTION_DELAY
      })
    });

    address controller = TransparentProxyFactory(
      MiscEthereum.TRANSPARENT_PROXY_FACTORY
    ).create(
        address(new PermissionedPayloadsController()),
        GovernanceV3Ethereum.EXECUTOR_LVL_1,
        abi.encodeCall(
          PermissionedPayloadsController.initialize,
          (
            GovernanceV3Ethereum.EXECUTOR_LVL_1,
            MiscEthereum.PROTOCOL_GUARDIAN,
            PAYLOADS_MANAGER,
            executors
          )
        )
      );

    executor.transferOwnership(controller);
    vm.stopBroadcast();

    console.log('permissionedPayloadsController', controller);
    console.log('executor', address(executor));
  }
}
