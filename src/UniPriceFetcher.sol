// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import {IERC20} from "@oz_tilt/contracts/interfaces/IERC20.sol";

import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import "./Errors.sol";

abstract contract PyroTokenWrapper {
    /*
        struct Configuration {
        address liquidityReceiver;
        IERC20 baseToken;
        address loanOfficer;
        bool pullPendingFeeRevenue;
    }
    */
    function config()
        public
        view
        virtual
        returns (address, address, address, bool);

    function redeemRate() public view virtual returns (uint);
}

enum TokenType {
    Unset,
    Base,
    Eth,
    LP,
    Pyro
}

contract UniPriceFetcher is Ownable {
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
    address weth;
    address dai;
    uint constant ONE = 1 ether;

    constructor(address routerAddress, address daiAddress) Ownable(msg.sender) {
        router = IUniswapV2Router02(routerAddress);
        weth = router.WETH();
        factory = IUniswapV2Factory(router.factory());
        dai = daiAddress;
    }

    mapping(address => TokenType) public tokenTypeMap;

    function setTokenTypeMap(
        address[] calldata tokens,
        TokenType[] calldata types
    ) external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            require(uint(types[i]) < 5, "invalid type");
            tokenTypeMap[tokens[i]] = types[i];
            validateMap(tokens[i], types[i]);
        }
    }

    function validateMap(address token, TokenType tokenType) private {
        if (tokenType == TokenType.Unset) {
            revert TokenTypeUnset(token);
        } else if (tokenType == TokenType.Eth && token != weth) {
            revert TokenFalselyClaimsToBeWeth(token, weth);
        } else if (tokenType == TokenType.LP) {
            IUniswapV2Pair pair = IUniswapV2Pair(token);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (factory.getPair(token0, token1) != token) {
                revert InvalidLP(token);
            }
            TokenType token0Type = tokenTypeMap[token0];
            TokenType token1Type = tokenTypeMap[token0];
            validateMap(token0, token0Type);
            validateMap(token1, token1Type);
        } else if (tokenType == TokenType.Pyro) {
            (, address baseToken, , ) = PyroTokenWrapper(token).config();
            TokenType baseTokenType = tokenTypeMap[baseToken];
            validateMap(baseToken, baseTokenType);
        }
    }

    function daiPriceOfToken(address token) public view returns (uint) {
        TokenType map = tokenTypeMap[token];
        if (map == TokenType.Unset) {
            revert TokenTypeUnset(token);
        }

        if (map == TokenType.Pyro) {
            //get redeem rate
            uint redeemRate = PyroTokenWrapper(token).redeemRate();
            (, address baseToken, , ) = PyroTokenWrapper(token).config();
            return (redeemRate * daiPriceOfToken(baseToken)) / (1 ether);
        } else if (map == TokenType.LP) {
            IUniswapV2Pair pair = IUniswapV2Pair(token);
            uint totalSupply = pair.totalSupply();
            address token0_a = pair.token0();
            address token1_a = pair.token1();
            IERC20 token0 = IERC20(token0_a);
            IERC20 token1 = IERC20(token1_a);
            uint bal_0 = token0.balanceOf(token);
            uint bal_1 = token1.balanceOf(token);

            uint combinedDollarValue = (daiPriceOfToken(token0_a) * bal_0) +
                (daiPriceOfToken(token1_a) * bal_1);
            return combinedDollarValue / totalSupply;
        } else {
            return daiPriceOfBaseToken(token, map == TokenType.Eth);
        }
    }

    function daiPriceOfTokens(
        address[] memory tokens
    ) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            prices[i] = daiPriceOfToken(tokens[i]);
        }
    }

    function daiPriceOfBaseToken(
        address token,
        bool isEth
    ) public view returns (uint) {
        uint wethPerDai = wethPriceOfBaseToken(dai, false);
        //W/D - 1000/3000
        //W/T  - 1000/50000
        //=>(W/T)/(W/D) = (W/T*D/W) = (D/T); = (1000/50000 * 3000/1000)
        uint wethPriceOfToken = wethPriceOfBaseToken(token, isEth);

        return (wethPriceOfToken * (ONE)) / wethPerDai;
    }

    function wethPriceOfBaseToken(
        address token,
        bool isEth
    ) public view returns (uint) {
        if (isEth) return ONE;

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        address pair = factory.getPair(token, weth);
        require(pair != address(0), "token without Weth pairing");
        uint tokenReserve = IERC20(token).balanceOf(pair);
        uint wethReserve = IERC20(weth).balanceOf(pair);
        return (wethReserve * ONE) / tokenReserve;
    }
}
