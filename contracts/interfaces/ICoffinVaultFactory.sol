// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface ICoffinVaultFactory {
    event AddressRegistryChanged(address newAddress);
    event VaultCreated(address owner, address indexed _newVault);
}
