// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import {ICoffinVaultFactory} from "./interfaces/ICoffinVaultFactory.sol";
import {CoffinVault} from "./CoffinVault.sol";

contract CoffinVaultFactory is ICoffinVaultFactory, Ownable {
    bool public deprecated;
    address public addressRegistry;

    mapping(address => address[]) public userVaults;

    constructor(address _addressRegistry) {
        deprecated = false;
        addressRegistry = _addressRegistry;
    }

    function createNewVault() external returns (address) {
        address newVaultAddress = address(new CoffinVault(addressRegistry));
        userVaults[msg.sender].push(newVaultAddress);
        emit VaultCreated(msg.sender, newVaultAddress);
        return newVaultAddress;
    }

    function getUserVaults(
        address _user
    ) external view returns (address[] memory) {
        return userVaults[_user];
    }

    function setAddressRegistry(address newAddress) external onlyOwner {
        addressRegistry = newAddress;
        emit AddressRegistryChanged(addressRegistry);
    }
}
