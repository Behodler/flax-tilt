// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import "./Oracle.sol";

interface ITilter {
    struct OracleSet {
        IUniswapV2Pair flx_ref_token;
        Oracle oracle;
    }
    struct UniVARS {
        address ref_token;
        IUniswapV2Factory factory;
        IUniswapV2Router02 router;
        address flax;
        OracleSet oracleSet;
        address issuer;
    }


    function setEnabled(bool enabled) external;

    function configure(
        address ref_token,
        address flx,
        address oracle,
        address issuer
    ) external;

    function refValueOfTilt(
        uint ref_amount,
        bool preview
    ) external view returns (uint flax_new_balance, uint lpTokens_created);

    function issue(
        address inputToken,
        uint amount,
        address recipient
    ) external payable;
}
