// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {ICoffinVaultFactory} from "./interfaces/ICoffinVaultFactory.sol";
import {CoffinVault} from "./CoffinVault.sol";

contract CoffinVaultFactory is ICoffinVaultFactory, Ownable {
    bool public deprecated;

    // address to strategy mapping
    mapping(address => address[]) public userVaults;

    constructor() {
        deprecated = false;
    }

    // function createNewVault() external returns (address) {
    //     // address newVaultAddress = address(new CoffinVault());
    //     userVaults[msg.sender].push(newVaultAddress);
    //     return newVaultAddress;
    // }

    function getUserVaults(
        address _user
    ) external view returns (address[] memory) {
        return userVaults[_user];
    }

    event VaultCreated(address indexed _newVault);
}
