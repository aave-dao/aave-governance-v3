// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GovernanceDataHelper} from '../src/contracts/dataHelpers/GovernanceDataHelper.sol';
import {PayloadsControllerDataHelper} from '../src/contracts/dataHelpers/PayloadsControllerDataHelper.sol';
import {VotingMachineDataHelper} from '../src/contracts/dataHelpers/VotingMachineDataHelper.sol';
import {MetaDelegateHelper} from '../src/contracts/dataHelpers/MetaDelegateHelper.sol';
import './GovBaseScript.sol';

abstract contract BaseContractHelpers is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    if (addresses.governance != address(0)) {
      addresses.governanceDataHelper = address(new GovernanceDataHelper());
      addresses.metaDelegateHelper = address(new MetaDelegateHelper());
    }

    if (addresses.votingMachine != address(0)) {
      addresses.votingMachineDataHelper = address(
        new VotingMachineDataHelper()
      );
    }

    if (addresses.payloadsController != address(0)) {
      addresses.payloadsControllerDataHelper = address(
        new PayloadsControllerDataHelper()
      );
    }
  }
}

contract Ethereum is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Avalanche is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Arbitrum is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Optimism is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Metis is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Base is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Gnosis is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Scroll is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Zksync is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Linea is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.LINEA;
  }
}

contract Celo is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }
}

contract Mantle is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }
}
contract Sonic is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONIC;
  }
}

contract Ink is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.INK;
  }
}

contract Soneium is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONEIUM;
  }
}

contract Plasma is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.PLASMA;
  }
}

contract Bob is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BOB;
  }
}

contract Xlayer is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.XLAYER;
  }
}

contract MegaEth is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MEGAETH;
  }
}

contract Monad is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MONAD;
  }
}
