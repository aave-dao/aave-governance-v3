// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';

abstract contract UpdateExecutorOwner {
  function targetOwner() public pure virtual returns (address);

  function executor() public pure virtual returns (address);

  function _changeOwner() internal {
    require(targetOwner() != address(0), 'NEW_OWNER_CANT_BE_0');
    require(executor() != address(0), 'PAYLOADS_CONTROLLER_CANT_BE_0');

    if (Ownable(executor()).owner() != targetOwner()) {
      Ownable(executor()).transferOwnership(targetOwner());
    }
  }
}

contract UpdateExecutorPermissionsMantle is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0xF089f77173A3009A98c45f49D547BF714A7B1e01; // PC
  }

  function executor() public pure override returns (address) {
    return 0x70884634D0098782592111A2A6B8d223be31CB7b; // Executor Lvl 1
  }
}

contract Mantle is Script, UpdateExecutorPermissionsMantle {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}

contract UpdateExecutorPermissionsSoneium is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x44D73D7C4b2f98F426Bf8B5e87628d9eE38ef0Cf; // PC
  }

  function executor() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }
}

contract Soneium is Script, UpdateExecutorPermissionsSoneium {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}

contract UpdateExecutorPermissionsPlasma is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0xe76EB348E65eF163d85ce282125FF5a7F5712A1d; // PC
  }

  function executor() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }
}

contract Plasma is Script, UpdateExecutorPermissionsPlasma {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}

contract UpdateExecutorPermissionsBob is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x17fa87007bfF1dC7e6b3a36ED936E6355e37237C; // PC
  }

  function executor() public pure override returns (address) {
    return 0x90800d1F54384523723eD3962c7Cd59d7866c83d; // Executor Lvl 1
  }
}

contract UpdateExecutorPermissionsXlayer is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x80e11cB895a23C901a990239E5534054C66476B5; // PC
  }

  function executor() public pure override returns (address) {
    return 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19; // Executor Lvl 1
  }
}

contract Xlayer is Script, UpdateExecutorPermissionsXlayer {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}

contract UpdateExecutorPermissionsMegaEth is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x80e11cB895a23C901a990239E5534054C66476B5; // PC
  }

  function executor() public pure override returns (address) {
    return 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19; // Executor Lvl 1
  }
}

contract MegaEth is Script, UpdateExecutorPermissionsMegaEth {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}


contract UpdateExecutorPermissionsMonad is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x442CA936e5E6Db875357d0A16481145c96dd9a82; // PC
  }

  function executor() public pure override returns (address) {
    return 0xa9d0EAFF48cE1DF468f9eAeb7e628c413343F6A2; // Executor Lvl 1
  }
}

contract Monad is Script, UpdateExecutorPermissionsMonad {
  function run() external {
    vm.startBroadcast();

    _changeOwner();

    vm.stopBroadcast();
  }
}
