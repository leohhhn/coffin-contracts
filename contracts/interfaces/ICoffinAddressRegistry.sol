// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICoffinAddressRegistry {
    function getAddress(bytes32 _identifier) external view returns (address);

    function setUniswap(address contractAddress) external;

    function setAave(address contractAddress) external;

    function setWETH(address contractAddress) external;

    function setGHO(address contractAddress) external;

    function setUSDC(address contractAddress) external;

    function getUniswap() external view returns (address);

    function getAave() external view returns (address);

    function getWETH() external view returns (address);

    function getGHO() external view returns (address);

    function getUSDC() external view returns (address);
}
