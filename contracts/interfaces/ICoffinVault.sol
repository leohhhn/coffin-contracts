// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICoffinVault {
    struct Position {
        address token; // 0x0 if ETH
        uint16 leverage; // passed in after getting ltv from getReserveData. ie ltv = 7500 (75%), max leverage = 7500
       
        bool active;
        uint256 amount; // if eth, same amount as msg.value  supply through .call(""){}
    }

    // user uses only single token at beginning. ie USDC/GHO
    function createPosition(Position memory _position) external;

    function createPositionETH(Position memory _position) external payable;

    function withdrawPosition() external;

    // function rebalancePosition() external;
}
