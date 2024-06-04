// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}