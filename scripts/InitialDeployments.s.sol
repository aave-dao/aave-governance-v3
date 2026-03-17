// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {
  GovernanceV3Avalanche
} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Metis} from 'aave-address-book/GovernanceV3Metis.sol';
import {GovernanceV3BNB} from 'aave-address-book/GovernanceV3BNB.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {GovernanceV3Gnosis} from 'aave-address-book/GovernanceV3Gnosis.sol';
import {GovernanceV3Scroll} from 'aave-address-book/GovernanceV3Scroll.sol';
import {GovernanceV3ZkSync} from 'aave-address-book/GovernanceV3ZkSync.sol';
import {GovernanceV3Linea} from 'aave-address-book/GovernanceV3Linea.sol';
import {GovernanceV3Sonic} from 'aave-address-book/GovernanceV3Sonic.sol';
import {GovernanceV3Mantle} from 'aave-address-book/GovernanceV3Mantle.sol';
import {GovernanceV3Ink} from 'aave-address-book/GovernanceV3Ink.sol';
import {GovernanceV3Soneium} from 'aave-address-book/GovernanceV3Soneium.sol';
import {GovernanceV3Plasma} from 'aave-address-book/GovernanceV3Plasma.sol';
import {GovernanceV3Celo} from 'aave-address-book/GovernanceV3Celo.sol';
import {GovernanceV3Bob} from 'aave-address-book/GovernanceV3Bob.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {MiscMetis} from 'aave-address-book/MiscMetis.sol';
import {MiscBNB} from 'aave-address-book/MiscBNB.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {MiscGnosis} from 'aave-address-book/MiscGnosis.sol';
import {MiscScroll} from 'aave-address-book/MiscScroll.sol';
import {MiscZkSync} from 'aave-address-book/MiscZkSync.sol';
import {MiscLinea} from 'aave-address-book/MiscLinea.sol';
import {MiscSonic} from 'aave-address-book/MiscSonic.sol';
import {MiscMantle} from 'aave-address-book/MiscMantle.sol';
import {MiscInk} from 'aave-address-book/MiscInk.sol';
import {MiscSoneium} from 'aave-address-book/MiscSoneium.sol';
import {MiscPlasma} from 'aave-address-book/MiscPlasma.sol';
import {MiscCelo} from 'aave-address-book/MiscCelo.sol';
import {MiscBob} from 'aave-address-book/MiscBob.sol';

import './GovBaseScript.sol';

/**
 * @notice this script contains the logic to generate the json file with the governance needed addresses specified in
 * GovBaseScript Addresses struct.
 * @dev the address file will be generated with address(0) and the msg.sender as owner and guardian if not otherwise
 * overriden.
 * @dev you should make sure that the crossChainController addresses json files have the proxyFactory, and if needed the create3Factory
 * If for some reason you need the create3Factory and its not in the cc addresses you can override the CREATE3_METHOD to deploy or return
 * the address (Create3 contracts can be found in solidity utils repository: https://github.com/bgd-labs/solidity-utils/tree/main/src/contracts/create3).
 */
abstract contract BaseInitialDeployment is GovBaseScript {
  function OWNER() public virtual returns (address) {
    return address(msg.sender); // as first owner we set deployer, this way its easier to configure
  }

  function GUARDIAN() public virtual returns (address) {
    return address(msg.sender);
  }

  function CREATE3_FACTORY() public view virtual returns (address) {
    return address(0);
  }

  function PROXY_FACTORY() public view virtual returns (address) {
    return address(0);
  }

  function CROSS_CHAIN_CONTROLLER() public view virtual returns (address) {
    return address(0);
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    require(PROXY_FACTORY() != address(0), 'PROXY_FACTORY is not set');
    require(
      CROSS_CHAIN_CONTROLLER() != address(0),
      'CROSS_CHAIN_CONTROLLER is not set'
    );
    addresses.create3Factory = CREATE3_FACTORY();
    addresses.chainId = TRANSACTION_NETWORK();
    addresses.owner = OWNER();
    addresses.guardian = GUARDIAN();
    addresses.proxyFactory = PROXY_FACTORY();
    addresses.crossChainController = CROSS_CHAIN_CONTROLLER();
  }
}

contract Ethereum is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Ethereum.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscEthereum.TRANSPARENT_PROXY_FACTORY;
  }

  function CREATE3_FACTORY() public pure override returns (address) {
    return MiscEthereum.CREATE_3_FACTORY;
  }
}

contract Polygon is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Polygon.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscPolygon.TRANSPARENT_PROXY_FACTORY;
  }

  function CREATE3_FACTORY() public pure override returns (address) {
    return MiscPolygon.CREATE_3_FACTORY;
  }
}

contract Avalanche is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Avalanche.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscAvalanche.TRANSPARENT_PROXY_FACTORY;
  }

  function CREATE3_FACTORY() public pure override returns (address) {
    return MiscAvalanche.CREATE_3_FACTORY;
  }
}

contract Optimism is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Optimism.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscOptimism.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Arbitrum is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Arbitrum.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscArbitrum.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Metis is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Metis.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscMetis.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Binance is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3BNB.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscBNB.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Base is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Base.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscBase.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Gnosis is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Gnosis.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscGnosis.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Scroll is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Scroll.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscScroll.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Zksync is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3ZkSync.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscZkSync.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Linea is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Linea.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.LINEA;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscLinea.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Celo is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Celo.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscCelo.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Sonic is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Sonic.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONIC;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscSonic.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Mantle is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Mantle.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscMantle.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Ink is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Ink.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.INK;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscInk.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Soneium is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Soneium.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONEIUM;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscSoneium.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Plasma is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Plasma.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.PLASMA;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscPlasma.TRANSPARENT_PROXY_FACTORY;
  }
}

contract Bob is BaseInitialDeployment {
  function GUARDIAN() public pure override returns (address) {
    return GovernanceV3Bob.GOVERNANCE_GUARDIAN;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BOB;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return MiscBob.TRANSPARENT_PROXY_FACTORY;
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return GovernanceV3Bob.CROSS_CHAIN_CONTROLLER;
  }
}

contract Xlayer is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.XLAYER;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return 0xEB0682d148e874553008730f0686ea89db7DA412;
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return 0xFdd46155fD3DA5B907AD3B9f9395366290f58097;
  }
}

contract MegaEth is BaseInitialDeployment {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MEGAETH;
  }

  function PROXY_FACTORY() public pure override returns (address) {
    return 0xEB0682d148e874553008730f0686ea89db7DA412;
  }

  function CROSS_CHAIN_CONTROLLER() public pure override returns (address) {
    return 0x5EE63ACb37AeCDc7e23ACA283098f8ffD9677BBe;
  }
}
