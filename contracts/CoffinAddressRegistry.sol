// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICoffinAddressRegistry.sol";

contract CoffinAddressRegistry is Ownable, ICoffinAddressRegistry {
    bytes32 private constant UNISWAPV3ROUTER = "UNISWAPV3R";
    bytes32 private constant AAVEV3POOL = "AAVEV3POOL";
    bytes32 private constant WETH = "WETH";
    bytes32 private constant GHO = "GHO";
    bytes32 private constant USDC = "USDC"; // aave faucet USDC

    mapping(bytes32 => address) public addresses;

    function getAddress(bytes32 _identifier) public view returns (address) {
        return addresses[_identifier];
    }

    function setUniswap(address contractAddress) external onlyOwner {
        _setAddress(UNISWAPV3ROUTER, contractAddress);
    }

    function setWETH(address contractAddress) external onlyOwner {
        _setAddress(WETH, contractAddress);
    }

    function setAave(address contractAddress) external onlyOwner {
        _setAddress(AAVEV3POOL, contractAddress);
    }

    function setGHO(address contractAddress) external onlyOwner {
        _setAddress(GHO, contractAddress);
    }

    function setUSDC(address contractAddress) external onlyOwner {
        _setAddress(USDC, contractAddress);
    }

    function getUniswap() external view returns (address) {
        return getAddress(UNISWAPV3ROUTER);
    }

    function getAave() external view returns (address) {
        return getAddress(AAVEV3POOL);
    }

    function getWETH() external view returns (address) {
        return getAddress(WETH);
    }

    function getGHO() external view returns (address) {
        return getAddress(GHO);
    }

    function getUSDC() external view returns (address) {
        return getAddress(USDC);
    }

    function _setAddress(
        bytes32 _identifier,
        address contractAddress
    ) internal {
        addresses[_identifier] = contractAddress;
    }
}
