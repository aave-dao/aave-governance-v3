// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {PermissionedPayloadsController, PayloadsControllerUtils, IPayloadsControllerCore} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import '../GovBaseScript.sol';

/**
 * @notice deploys a PermissionedPayloadsController and its Executor for Sentora on Ethereum.
 * @dev the Aave v4 Security Council is the controller owner and guardian, so it can change the execution delay and
 *      cancel payloads. The proxy admin owner is the governance Executor Lvl1, so only governance can upgrade.
 */
contract Ethereum is GovBaseScript {
  // Sentora Operator Safe
  address internal constant PAYLOADS_MANAGER =
    0x6748f83C1d1F49Dffb715078B68180536aE7F40F;

  uint40 internal constant EXECUTION_DELAY = 2 days;

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    require(block.chainid == ChainIds.ETHEREUM, 'WRONG_NETWORK');

    addresses.sentoraPermissionedExecutor = address(new Executor());
    addresses.sentoraPermissionedPayloadsControllerImpl = address(
      new PermissionedPayloadsController()
    );

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        executor: addresses.sentoraPermissionedExecutor,
        delay: EXECUTION_DELAY
      })
    });

    addresses.sentoraPermissionedPayloadsController = TransparentProxyFactory(
      MiscEthereum.TRANSPARENT_PROXY_FACTORY
    ).create(
        addresses.sentoraPermissionedPayloadsControllerImpl,
        GovernanceV3Ethereum.EXECUTOR_LVL_1,
        abi.encodeCall(
          PermissionedPayloadsController.initialize,
          (
            MiscEthereum.V4_SECURITY_COUNCIL,
            MiscEthereum.V4_SECURITY_COUNCIL,
            PAYLOADS_MANAGER,
            executors
          )
        )
      );

    Ownable(addresses.sentoraPermissionedExecutor).transferOwnership(
      addresses.sentoraPermissionedPayloadsController
    );
  }
}
