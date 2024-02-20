// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';

abstract contract BaseDeployExecutorLvl1 is GovBaseScript {
  function getExecutorOwner() public view virtual returns (address) {
    return msg.sender;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.executorLvl1 = address(new Executor());

    if (addresses.chainId == ChainIds.ETHEREUM) {
      Ownable(addresses.executorLvl1).transferOwnership(getExecutorOwner());
    }
  }
}

contract Ethereum is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }
}

contract Avalanche is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.METIS_BRIDGE_EXECUTOR;
  }
}

contract Base is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.BASE_BRIDGE_EXECUTOR;
  }
}

contract Binance is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Gnosis is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Scroll is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Celo is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }
}

contract Ethereum_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Optimism_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_GOERLI;
  }
}

contract Arbitrum_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_GOERLI;
  }
}

contract Metis_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Scroll_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.SCROLL_SEPOLIA;
  }
}
