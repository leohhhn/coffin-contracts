// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import "@aave/core-v3/contracts/misc/interfaces/IWETH.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoffinAddressRegistry.sol";
import "./interfaces/ICoffinVault.sol";
import "hardhat/console.sol";

contract CoffinVault is Ownable, ICoffinVault, IERC721Receiver {
    using Counters for Counters.Counter;

    Counters.Counter private _lpNFTIDCounter;

    // AAVE Pool Proxy address
    ICoffinAddressRegistry public addressRegistry;
    uint24 public constant poolFee = 3000;

    Position[] public positions;
    mapping(uint256 => Deposit) public deposits;

    constructor(address _addressRegistry) {
        addressRegistry = ICoffinAddressRegistry(_addressRegistry);
        // give user ownership of vault
        transferOwnership(tx.origin);
    }

    // user needs to approve spending token before calling this function
    function createLeveragedPosition(
        Position memory _position
    ) external onlyOwner {
        // assume only USDC for hack
        require(
            _position.token != address(0),
            "CoffinVault:createLeveragedPosition:: Invalid token address"
        );

        require(
            _position.leverage >= 100,
            "CoffinVault:createLeveragedPosition:: Leverage cannot be less than x1"
        );

        // get reserve data for collateral, in our case weth
        address WETH = addressRegistry.getWETH();
        uint16 ltv = getLTVForAsset(WETH);
        require(
            ltv >= 100,
            "CoffinVault:createLeveragedPosition:: Reserve LTV too low"
        );

        // example math for frontend calculation of multiplier
        // ltv 7500 => 75% from aave
        // => max leverage = x 1.75 => 1750 bp

        // check if leverage provided is possible
        require(
            _position.leverage <= ltv,
            "CoffinVault:createLeveragedPosition:: Leverage above LTV"
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

        _position.active = true;
        positions.push(_position);

        emit CreatedLeveragedPosition(vault, borrowedGHOAmount, _position);
    }

    function createLeveragedPositionETH(
        Position memory _position
    ) external payable onlyOwner {
        // doesnt check position.amount. just uses msg.value instead
        require(
            _position.token == address(0),
            "CoffinVault:createLeveragedPositionETH:: Token address must be 0x0"
        );

        require(
            _position.leverage >= 100,
            "CoffinVault:createLeveragedPositionETH:: Leverage cannot be less than x1"
        );

        // get reserve data for collateral, in our case weth
        address wethAddress = addressRegistry.getWETH();
        uint16 ltv = getLTVForAsset(wethAddress);
        require(
            ltv >= 100,
            "CoffinVault:createLeveragedPositionETH:: Reserve LTV too low"
        );

        // check if leverage provided is possible
        require(
            _position.leverage <= ltv,
            "CoffinVault:createLeveragedPositionETH:: Leverage above LTV"
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

        _position.active = true;
        positions.push(_position);
        emit CreatedLeveragedPosition(vault, borrowedGHOAmount, _position);
    }

    // should be called in succession w createLeveragedPosition(ETH).
    // takes max amount of GHO, splits in half for weth then >
    // deposits 50/50 GHO/WETH into LP pool
    // assumed address(this) already has x amount of GHO
    function provideLiquidity(
        uint256 minTick,
        uint256 maxTick
    )
        external
        onlyOwner
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        address GHO = addressRegistry.getGHO();
        address WETH = addressRegistry.getWETH();

        require(
            IERC20(GHO).balanceOf(address(this)) > 0,
            "CoffinVault:provideLiquidity:: Not enough GHO in valut."
        );
        uint256 lpGHOAmount = IERC20(GHO).balanceOf(address(this)) / 2;

        // swap 50% of GHO for WETH
        ISwapRouter swapRouter = ISwapRouter(addressRegistry.getUniswap());
        TransferHelper.safeApprove(GHO, address(swapRouter), ghoAmount / 2);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: GHO,
                tokenOut: WETH,
                fee: poolFee, // assuming there exists a USDC/WETH 0.3% pool
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: lpGHOAmount, // 50% of GHO
                amountOutMinimum: 0, // todo set in prod
                sqrtPriceLimitX96: 0 // todo set in prod
            });

        uint256 wethAmount = swapRouter.exactInputSingle(params);

        IERC20(WETH).approve(address(nonfungiblePositionManager), wethAmount);
        IERC20(GHO).approve(address(nonfungiblePositionManager), lpGHOAmount);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: GHO,
                token1: WETH,
                fee: poolFee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: lpGHOAmount,
                amount1Desired: wethAmount,
                amount0Min: 0, // todo set in prod
                amount1Min: 0, // todo set in prod
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        if (amount0 < amount0ToAdd) {
            dai.approve(address(nonfungiblePositionManager), 0);
            uint refund0 = amount0ToAdd - amount0;
            dai.transfer(msg.sender, refund0);
        }
        if (amount1 < amount1ToAdd) {
            weth.approve(address(nonfungiblePositionManager), 0);
            uint refund1 = amount1ToAdd - amount1;
            weth.transfer(msg.sender, refund1);
        }
    }

    function withdrawPosition() external {}

    function getUserPositions() external view returns (Position[] memory) {
        return positions;
    }

    function getLTVForAsset(address _asset) internal view returns (uint16) {
        IPool aavePool = IPool(addressRegistry.getAave());
        DataTypes.ReserveData memory reserveData = aavePool.getReserveData(
            _asset
        );
        return uint16(reserveData.configuration.data);
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
