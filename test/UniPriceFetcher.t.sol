// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC20} from "@oz_tilt/contracts/token/ERC20/ERC20.sol";
import {TokenLockupPlans} from "@hedgey/lockup/TokenLockupPlans.sol";
import {HedgeyAdapter} from "@behodler/flax/HedgeyAdapter.sol";
import {Coupon} from "@behodler/flax/Coupon.sol";
import {Issuer} from "@behodler/flax/Issuer.sol";
import {UniswapV2Router02} from "@uniswap/periphery/UniswapV2Router02.sol";
import {WETH9} from "@uniswap/periphery/test/WETH9.sol";
import {UniswapV2Factory} from "@uniswap/core/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import {Oracle} from "../src/Oracle.sol";
import {Tilter} from "../src/Tilter.sol";
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import "../src/Errors.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";
import {MockToken, PyroToken} from "../test/MockPyroToken.sol";
import {UniPriceFetcher, TokenType} from "../src/UniPriceFetcher.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";

contract FakePair {
    address public token0;
    address public token1;

    constructor(address t0, address t1) {
        token0 = t0;
        token1 = t1;
    }
}

contract UniPriceFetcherTest is Test {
    MockToken flax;
    MockToken eye;
    MockToken scx;
    MockToken shib;
    MockToken uniGov;
    MockToken dai;

    UniswapV2Router02 router;
    UniPriceFetcher uniPriceFetcher;

    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    function deployBaseToken(string memory name) private returns (MockToken) {
        MockToken token = new MockToken(name, name);

        token.mint(address(this), 1000_000_000_000 ether);
        return token;
    }

    function setUp() public {
        flax = deployBaseToken("Flax");
        eye = deployBaseToken("Eye");
        scx = deployBaseToken("SCX");
        shib = deployBaseToken("SHIB");
        uniGov = deployBaseToken("UNI");
        dai = deployBaseToken("Dai");

        router = new UniswapV2Router02(
            address(new UniswapV2Factory(address(this))),
            address(new WETH9())
        );

        vm.deal(address(this), 100_001 ether);
        WETH().deposit{value: 100_000 ether}();

        IUniswapV2Pair scx_eye = createPair(address(scx), address(eye), 20);

        IUniswapV2Pair scx_eth = createEthPair(address(scx), 1000);
        IUniswapV2Pair eye_eth = createEthPair(address(eye), 20_000);
        IUniswapV2Pair shiba_eth = createEthPair(address(shib), 4000_000);
        IUniswapV2Pair uni_eth = createEthPair(address(uniGov), 2000);
        IUniswapV2Pair flx_eth = createEthPair(address(flax), 50_000);
        IUniswapV2Pair dai_eth = createEthPair(address(dai), 3000);

        PyroToken pyro_scx_eye = createPyroToken(
            address(scx_eye),
            "scx/eye",
            20
        );
        PyroToken pyro_scx_eth = createPyroToken(
            address(scx_eth),
            "scx/eth",
            12
        );

        uniPriceFetcher = new UniPriceFetcher(address(router), address(dai));

        address[] memory tokens = new address[](11);
        TokenType[] memory tokenTypes = new TokenType[](11);
        uint i = 0;
        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(eye);

        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(scx);

        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(WETH());

        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(shib);

        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(flax);

        tokenTypes[i] = TokenType.Base;
        tokens[i++] = address(uniGov);

        tokenTypes[i] = TokenType.LP;
        tokens[i++] = address(scx_eth);

        tokenTypes[i] = TokenType.LP;
        tokens[i++] = address(scx_eye);

        tokenTypes[i] = TokenType.Pyro;
        tokens[i++] = address(pyro_scx_eth);

        tokenTypes[i] = TokenType.Pyro;
        tokens[i++] = address(pyro_scx_eye);

        tokenTypes[i] = TokenType.Eth;
        tokens[i++] = address(WETH());

        uniPriceFetcher.setTokenTypeMap(tokens, tokenTypes);
        // uniPriceFetcher.setTradeAmount((1 ether)/1000);
    }

    function test_setup() public {}

    uint constant ONE = 1 ether;

    function test_price_base_tokens() public {
        address[] memory baseTokens = new address[](6);
        uint i;
        baseTokens[i++] = address(flax);

        baseTokens[i++] = address(eye);
        baseTokens[i++] = address(scx);
        baseTokens[i++] = address(shib);
        baseTokens[i++] = address(uniGov);
        baseTokens[i++] = address(WETH());

        uint[] memory prices = uniPriceFetcher.daiPriceOfTokens(baseTokens);
        uint numerator = (ONE * 3000);
        uint expectedFlaxPrice = numerator / 50000;
        uint expectedEyePrice = numerator / 20_000;
        uint expectedSCXPrice = numerator / 1000;
        uint expectedShibPrice = numerator / 4000_000;
        uint expectedUniPrice = numerator / 2000;
        uint expectedWethPrice = numerator;
        uint precision_loss = 1e4;

        vm.assertEq(
            prices[0] / precision_loss,
            expectedFlaxPrice / precision_loss
        );
        vm.assertEq(
            prices[1] / precision_loss,
            expectedEyePrice / precision_loss
        );
        vm.assertEq(
            prices[2] / precision_loss,
            expectedSCXPrice / precision_loss
        );
        vm.assertEq(
            prices[3] / precision_loss,
            expectedShibPrice / precision_loss
        );
        vm.assertEq(
            prices[4] / precision_loss,
            expectedUniPrice / precision_loss
        );
        vm.assertEq(
            prices[5] / (precision_loss * 1000),
            expectedWethPrice / (precision_loss * 1000)
        );
    }

    function test_price_unmapped_fails() public {
        MockToken someOtherToken = new MockToken("UN", "MAPPED");
        someOtherToken.mint(address(this), (1 ether) * (1e12));
        createEthPair(address(someOtherToken), 2000);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenTypeUnset.selector,
                address(someOtherToken)
            )
        );
        uniPriceFetcher.daiPriceOfToken(address(someOtherToken));

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenTypeUnset.selector,
                address(someOtherToken)
            )
        );
        address[] memory tokens = new address[](1);
        tokens[0] = address(someOtherToken);
        uniPriceFetcher.daiPriceOfTokens(tokens);
    }

    function test_incorrect_weth_mapping() public {
        MockToken someOtherToken = new MockToken("UN", "MAPPED");
        someOtherToken.mint(address(this), (1 ether) * (1e12));

        address[] memory tokens = new address[](1);
        tokens[0] = address(someOtherToken);
        TokenType[] memory tokenTypes = new TokenType[](1);
        tokenTypes[0] = TokenType.Eth;

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenFalselyClaimsToBeWeth.selector,
                address(someOtherToken),
                address(WETH())
            )
        );
        uniPriceFetcher.setTokenTypeMap(tokens, tokenTypes);
    }

    function test_invalid_LP() public {
        FakePair fakeLP = new FakePair(address(WETH()), address(dai));

        address[] memory tokens = new address[](1);
        tokens[0] = address(fakeLP);
        TokenType[] memory tokenTypes = new TokenType[](1);
        tokenTypes[0] = TokenType.LP;

        vm.expectRevert(
            abi.encodeWithSelector(InvalidLP.selector, address(fakeLP))
        );
        uniPriceFetcher.setTokenTypeMap(tokens, tokenTypes);
    }

    function createEthPair(
        address token,
        uint ratio
    ) private returns (IUniswapV2Pair) {
        return createPair(address(WETH()), token, ratio);
    }

    function createPair(
        address token0,
        address token1,
        uint ratio
    ) private returns (IUniswapV2Pair) {
        factory().createPair(token0, token1);
        address pairAddress = factory().getPair(token0, token1);
        ERC20(token0).transfer(pairAddress, 1000 ether);
        ERC20(token1).transfer(pairAddress, (1000 ether) * ratio);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        pair.mint(address(this));
        return pair;
    }

    function createPyroToken(
        address baseToken,
        string memory name,
        uint initialBurnPerc
    ) private returns (PyroToken) {
        require(initialBurnPerc < 100, "initialBurnPerc must be % (0-100)");
        string memory pyroName = string(abi.encode("Pyro", name));
        PyroToken pyro = new PyroToken(baseToken, pyroName, pyroName);
        ERC20(baseToken).approve(address(pyro), type(uint).max);
        uint balance = ERC20(baseToken).balanceOf(address(this));
        uint mintAmount = (balance) / 100;
        pyro.mint(mintAmount);
        pyro.burn((mintAmount * initialBurnPerc) / 100);
        return pyro;
    }
}
