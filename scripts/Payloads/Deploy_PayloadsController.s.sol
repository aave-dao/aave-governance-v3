// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {PayloadsController, IPayloadsController} from '../../src/contracts/payloads/PayloadsController.sol';
import {IPayloadsControllerCore} from '../../src/contracts/payloads/PayloadsControllerCore.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {PayloadsControllerExtended} from '../extendedContracts/PayloadsController.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

abstract contract BaseDeployPayloadsController is GovBaseScript {
  function GOVERNANCE_NETWORK() public view virtual returns (uint256);

  function OWNER() public view virtual returns (address) {
    return _getAddresses(TRANSACTION_NETWORK()).executorLvl1;
  }

  function isTest() public view virtual returns (bool) {
    return false;
  }

  function LVL1_DELAY() public view virtual returns (uint40) {
    return uint40(1 days);
  }

  function LVL2_DELAY() public view virtual returns (uint40) {
    return uint40(7 days);
  }

  function getExecutorLvl1()
    public
    view
    returns (IPayloadsControllerCore.UpdateExecutorInput memory)
  {
    return
      IPayloadsControllerCore.UpdateExecutorInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        executorConfig: IPayloadsControllerCore.ExecutorConfig({
          executor: _getAddresses(TRANSACTION_NETWORK()).executorLvl1,
          delay: LVL1_DELAY()
        })
      });
  }

  function getExecutorLvl2()
    public
    view
    returns (IPayloadsControllerCore.UpdateExecutorInput memory)
  {
    return
      IPayloadsControllerCore.UpdateExecutorInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        executorConfig: IPayloadsControllerCore.ExecutorConfig({
          executor: _getAddresses(TRANSACTION_NETWORK()).executorLvl2,
          delay: LVL2_DELAY()
        })
      });
  }

  function getExecutors()
    public
    view
    virtual
    returns (IPayloadsControllerCore.UpdateExecutorInput[] memory)
  {
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = getExecutorLvl1();
    return executors;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    GovDeployerHelpers.Addresses memory govAddresses = _getAddresses(
      GOVERNANCE_NETWORK()
    );

    // deploy payloadsController
    if (isTest()) {
      addresses.payloadsControllerImpl = address(
        new PayloadsControllerExtended(
          addresses.crossChainController,
          govAddresses.governance,
          govAddresses.chainId
        )
      );
    } else {
      addresses.payloadsControllerImpl = address(
        new PayloadsController(
          addresses.crossChainController,
          govAddresses.governance,
          govAddresses.chainId
        )
      );
    }

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = getExecutors();

    addresses.payloadsController = TransparentProxyFactory(
      addresses.proxyFactory
    ).createDeterministic(
        addresses.payloadsControllerImpl,
        addresses.executorLvl1, // owner of proxy that will be deployed
        abi.encodeWithSelector(
          IPayloadsControllerCore.initialize.selector,
          OWNER(),
          addresses.guardian,
          executors
        ),
        Constants.PAYLOADS_CONTROLLER_SALT
      );

    //    if (addresses.chainId != ChainIds.ETHEREUM) {
    //      for (uint256 i = 0; i < executors.length; i++) {
    //        Ownable(address(executors[i].executorConfig.executor))
    //          .transferOwnership(addresses.payloadsController);
    //      }
    //    }

    addresses.proxyAdminPayloadsController = TransparentProxyFactory(
      addresses.proxyFactory
    ).getProxyAdmin(addresses.payloadsController);
  }
}

contract Ethereum is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getExecutors()
    public
    view
    override
    returns (IPayloadsControllerCore.UpdateExecutorInput[] memory)
  {
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](2);
    executors[0] = getExecutorLvl1();
    executors[1] = getExecutorLvl2();
    return executors;
  }
}

contract Avalanche is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Optimism is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Arbitrum is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Metis is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Binance is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Base is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Gnosis is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Scroll is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Mantle is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Sonic is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONIC;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Zksync is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Linea is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.LINEA;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Celo is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ink is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.INK;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Soneium is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONEIUM;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Plasma is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.PLASMA;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Bob is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BOB;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Xlayer is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.XLAYER;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract MegaEth is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MEGAETH;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Monad is BaseDeployPayloadsController {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MONAD;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}
