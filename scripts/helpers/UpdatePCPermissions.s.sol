// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import {
  OwnableWithGuardian,
  IWithGuardian
} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

abstract contract UpdatePayloadsControllerPermissions {
  function targetOwner() public pure virtual returns (address);

  function targetGovernanceGuardian() public pure virtual returns (address);

  function govContractsToUpdate()
    public
    pure
    virtual
    returns (address[] memory);

  function _changeOwnerAndGuardian(
    address owner,
    address guardian,
    address[] memory contracts
  ) internal {
    require(owner != address(0), 'NEW_OWNER_CANT_BE_0');
    require(guardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    for (uint256 i = 0; i < contracts.length; i++) {
      OwnableWithGuardian contractWithAC = OwnableWithGuardian(contracts[i]);
      try contractWithAC.guardian() returns (address currentGuardian) {
        if (currentGuardian != guardian) {
          IWithGuardian(contracts[i]).updateGuardian(guardian);
        }
      } catch {}
      if (contractWithAC.owner() != owner) {
        contractWithAC.transferOwnership(owner);
      }
    }
  }

  function _changeOwnerAndGuardian() internal {
    _changeOwnerAndGuardian(
      targetOwner(),
      targetGovernanceGuardian(),
      govContractsToUpdate()
    );
  }
}

contract UpdatePCPermissionsMantle is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x70884634D0098782592111A2A6B8d223be31CB7b; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x14816fC7f443A9C834d30eeA64daD20C4f56fBCD;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0xF089f77173A3009A98c45f49D547BF714A7B1e01); // PC
    return contracts;
  }
}

contract Mantle is Script, UpdatePCPermissionsMantle {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsInk is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x1bBcC6F0BB563067Ca45450023a13E34fa963Fa9;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0x44D73D7C4b2f98F426Bf8B5e87628d9eE38ef0Cf); // PC
    return contracts;
  }
}

contract Ink is Script, UpdatePCPermissionsInk {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsSoneium is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x19CE4363FEA478Aa04B9EA2937cc5A2cbcD44be6;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0x44D73D7C4b2f98F426Bf8B5e87628d9eE38ef0Cf); // PC
    return contracts;
  }
}

contract Soneium is Script, UpdatePCPermissionsSoneium {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsPlasma is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x19CE4363FEA478Aa04B9EA2937cc5A2cbcD44be6;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0xe76EB348E65eF163d85ce282125FF5a7F5712A1d); // PC
    return contracts;
  }
}

contract Plasma is Script, UpdatePCPermissionsPlasma {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsXlayer is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0xeB55A63bf9993d80c86D47f819B5eC958c7C127B;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0x80e11cB895a23C901a990239E5534054C66476B5); // PC
    return contracts;
  }
}

contract Xlayer is Script, UpdatePCPermissionsXlayer {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsMegaEth is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x5a578ee1dA2c798Be60036AdDD223Ac164d948Af;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = 0x80e11cB895a23C901a990239E5534054C66476B5; // PC
    return contracts;
  }
}

contract MegaEth is Script, UpdatePCPermissionsMegaEth {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}

contract UpdatePCPermissionsMonad is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0xa9d0EAFF48cE1DF468f9eAeb7e628c413343F6A2; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x056E4C4E80D1D14a637ccbD0412CDAAEc5B51F4E;
  }

  function govContractsToUpdate()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory contracts = new address[](1);
    contracts[0] = 0x442CA936e5E6Db875357d0A16481145c96dd9a82; // PC
    return contracts;
  }
}

contract Monad is Script, UpdatePCPermissionsMonad {
  function run() external {
    vm.startBroadcast();

    _changeOwnerAndGuardian();

    vm.stopBroadcast();
  }
}
