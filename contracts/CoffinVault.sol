// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import "@aave/core-v3/contracts/misc/interfaces/IWETH.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoffinAddressRegistry.sol";
import "./interfaces/ICoffinVault.sol";
import "hardhat/console.sol";

contract CoffinVault is Ownable, ICoffinVault {
    using Counters for Counters.Counter;

    Counters.Counter private _positionIDCounter;

    // AAVE Pool Proxy address
    ICoffinAddressRegistry public addressRegistry;
    uint24 public constant poolFee = 3000;

    mapping(uint256 => Position) positions;

    constructor(address _addressRegistry) {
        addressRegistry = ICoffinAddressRegistry(_addressRegistry);
        // give user ownership of vault
        transferOwnership(tx.origin);
    }

    // user needs to approve spending token before calling this function
    function createLeveragedPosition(Position memory _position) external {
        // assume only USDC
        require(
            _position.token != address(0),
            "CoffinVault:createPosition:: Invalid token address"
        );

        require(
            _position.leverage >= 100,
            "CoffinVault:createPosition:: Leverage cannot be less than x1"
        );

        // get reserve data for collateral, in our case weth
        address WETH = addressRegistry.getWETH();
        uint16 ltv = getLTVForAsset(WETH);
        require(ltv >= 100, "CoffinVault:createPosition:: Reserve LTV too low");

        // example math for frontend calculation of multiplier
        // ltv 7500 => 75% from aave
        // => max leverage = x 1.75 => 1750 bp

        // check if leverage provided is possible
        require(
            _position.leverage <= ltv,
            "CoffinVault:createPosition:: Leverage above LTV"
        );

        address vault = address(this);
        address USDC = addressRegistry.getUSDC();

        ISwapRouter swapRouter = ISwapRouter(addressRegistry.getUniswap());
        TransferHelper.safeTransferFrom(
            USDC,
            msg.sender,
            vault,
            _position.amount
        );

        TransferHelper.safeApprove(USDC, address(swapRouter), _position.amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH,
                fee: poolFee, // assuming there exists a USDC/WETH 0.3% pool
                recipient: vault,
                deadline: block.timestamp,
                amountIn: _position.amount,
                amountOutMinimum: 0, // todo set in prod
                sqrtPriceLimitX96: 0 // todo set in prod
            });

        uint256 wethAmount = swapRouter.exactInputSingle(params);

        IPool aavePool = IPool(addressRegistry.getAave());
        // supply weth to aave
        aavePool.supply(WETH, wethAmount, msg.sender, 0);

        (uint256 totalCollateralETH, , , , , ) = aavePool.getUserAccountData(
            vault // todo check this
        );

        // Calculate borrow amount
        uint256 maxBorrowAmountInWei = (totalCollateralETH *
            _position.leverage) / 10000;

        address GHO = addressRegistry.getGHO();

        aavePool.borrow(GHO, maxBorrowAmountInWei, 1, 0, vault);

        uint256 borrowedGHOAmount = IERC20(GHO).balanceOf(vault);

        emit CreatedLeveragedPosition(vault, borrowedGHOAmount);
    }

    function createLeveragedPositionETH(
        Position memory _position
    ) external payable {
        // doesnt check position.amount. just uses msg.value instead
        require(
            _position.token == address(0),
            "CoffinVault:createPosition:: Token address must be 0x0"
        );

        require(
            _position.leverage >= 100,
            "CoffinVault:createPosition:: Leverage cannot be less than x1"
        );

        // get reserve data for collateral, in our case weth
        address wethAddress = addressRegistry.getWETH();
        uint16 ltv = getLTVForAsset(wethAddress);
        require(ltv >= 100, "CoffinVault:createPosition:: Reserve LTV too low");

        // check if leverage provided is possible
        require(
            _position.leverage <= ltv,
            "CoffinVault:createPosition:: Leverage above LTV"
        );

        address vault = address(this);

        IWETH(wethAddress).deposit{value: msg.value}();

        IPool aavePool = IPool(addressRegistry.getAave());

        // supply weth to aave
        aavePool.supply(wethAddress, msg.value, msg.sender, 0);

        (uint256 totalCollateralETH, , , , , ) = aavePool.getUserAccountData(
            vault // todo check this
        );

        // Calculate borrow amount
        uint256 maxBorrowAmountInWei = (totalCollateralETH *
            _position.leverage) / 10000;

        address GHO = addressRegistry.getGHO();

        aavePool.borrow(GHO, maxBorrowAmountInWei, 1, 0, vault);

        uint256 borrowedGHOAmount = IERC20(GHO).balanceOf(vault);

        emit CreatedLeveragedPosition(vault, borrowedGHOAmount);
    }

    function withdrawPosition() external {}

    function getPosition(
        uint256 _positionID
    ) external view returns (Position memory) {
        return positions[_positionID];
    }

    function getLTVForAsset(address _asset) internal view returns (uint16) {
        IPool aavePool = IPool(addressRegistry.getAave());
        DataTypes.ReserveData memory reserveData = aavePool.getReserveData(
            _asset
        );
        return uint16(reserveData.configuration.data);
    }
}
