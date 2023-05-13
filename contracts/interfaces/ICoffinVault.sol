// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICoffinVault {
    event CreatedLeveragedPosition(address vault, uint256 indexed borrowedAmountOfGHO); // todo see what is needed on the front

    struct Position {
        address token; // 0x0 if ETH
        uint16 leverage; // passed in after getting ltv from getReserveData. ie ltv = 7500 (75%), max leverage = 7500
        bool active;
        uint256 amount; // if eth, same amount as msg.value  supply through .call(""){}
    }

    // user uses only single token at beginning. ie USDC/GHO
    function createLeveragedPosition(Position memory _position) external;

    function createLeveragedPositionETH(Position memory _position) external payable;

    function withdrawPosition() external;

    // function rebalancePosition() external;
}
