// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Coupon} from "@behodler/flax/Coupon.sol";
import {Issuer} from "@behodler/flax/Issuer.sol";
import "@behodler/flax/Multicall3.sol";
import {TokenLockupPlans} from "@hedgey/lockup/TokenLockupPlans.sol";
import {HedgeyAdapter} from "@behodler/flax/HedgeyAdapter.sol";
import {UniswapV2Router02} from "@uniswap/periphery/UniswapV2Router02.sol";
import {WETH9} from "@uniswap/periphery/test/WETH9.sol";
import {UniswapV2Factory} from "@uniswap/core/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import {Oracle} from "../src/Oracle.sol";
import "../src/TilterFactory.sol";

import {Vm} from "forge-std/Vm.sol";

contract DeployContracts is Script {
    UniswapV2Router02 router;

    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    function run() public {
        AddressToString addressToString = new AddressToString();
        vm.startBroadcast();

        //Deploy Multicall3
        Multicall3 multicall3 = new Multicall3();
        // Deploy Flx
        Coupon flax = new Coupon("Flax", "FLX");
        flax.setMinter(msg.sender, true);
        flax.mint(1e20 * 35, msg.sender);
        Coupon mockInputTokenBurnable = new Coupon("EYE", "EYE");
        Coupon mockInputTokenNonBurnable = new Coupon(
            "Uni V2 EYE/SCX",
            "EYE/SCX"
        );
        mockInputTokenNonBurnable.setMinter(msg.sender, true);
        mockInputTokenNonBurnable.mint((6 ether) / 10000, msg.sender);
        mockInputTokenBurnable.setMinter(msg.sender, true);
        Coupon SCX = new Coupon("Scarcity", "SCX");
        SCX.setMinter(msg.sender, true);
        Coupon PyroSCX_EYE = new Coupon(
            "Pryo(SCX/EYE Uni V2 LP)",
            "PyroSCXEYE"
        );

        PyroSCX_EYE.setMinter(msg.sender, true);

        mockInputTokenBurnable.mint(13 ether, msg.sender);
        SCX.mint((101107 ether) / 1000, msg.sender);

        PyroSCX_EYE.mint(uint((323220 ether) / uint(2200)), msg.sender);
        // Deploy Issuer with the address of Coupon

        TokenLockupPlans tokenLockupPlan = new TokenLockupPlans("Hedge", "HDG");
        HedgeyAdapter hedgeyAdapter = new HedgeyAdapter(
            address(flax),
            address(tokenLockupPlan)
        );
        Issuer issuer = new Issuer(address(flax), address(hedgeyAdapter));
        flax.setMinter(address(issuer), true);
        PyroSCX_EYE.approve(address(issuer), uint(type(uint).max));
        issuer.setLimits(1000, 60, 180, 1);
        issuer.setTokenInfo(
            address(mockInputTokenBurnable),
            true,
            true,
            10_000_000_000
        );
        issuer.setTokenInfo(address(SCX), true, true, 10_000_000_000);
        issuer.setTokenInfo(address(PyroSCX_EYE), true, true, 10_000_000_000);

        issuer.setTokenInfo(
            address(mockInputTokenNonBurnable),
            true,
            false,
            10_000_000_000
        );

        //SETUP UNISWAP PAIR AND OoRACLE
        router = new UniswapV2Router02(
            address(new UniswapV2Factory(msg.sender)),
            address(new WETH9())
        );

        //create FLX/ETH pair
        factory().createPair(address(flax), address(WETH()));
        IUniswapV2Pair flx_weth_pair = IUniswapV2Pair(
            factory().getPair(address(flax), address(WETH()))
        );

        flax.mint(10 ether, address(flx_weth_pair));
        WETH().deposit{value: 1 ether}();
        WETH().transfer(address(flx_weth_pair), 1 ether);
        flx_weth_pair.mint(msg.sender);

        //trade a little
        flax.mint(10 ether, msg.sender);
        flax.approve(address(flx_weth_pair), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(flax);
        path[1] = address(WETH());

        uint tradeAmount = (1 ether) / 20;

        uint wethOut = router.getAmountOut(tradeAmount, 10 ether, 1 ether);
        flax.approve(address(router), type(uint).max);
        router.swapExactTokensForETH(
            tradeAmount,
            wethOut,
            path,
            msg.sender,
            type(uint).max
        );

        //CREATE ORACLE
        Oracle oracle = new Oracle(address(factory()));
        oracle.RegisterPair(address(flx_weth_pair), 1);

        //ISSUER REGISTER PAIR
        issuer.setTokenInfo(address(flx_weth_pair), true, false, 11574074);

        //Deploy TilterFactory
        TilterFactory tilterFactory = new TilterFactory(
            address(router),
            address(flax),
            address(oracle),
            address(issuer)
        );
        tilterFactory.deploy(address(WETH()));
        address ethTilter = tilterFactory.getEthTilter();


        vm.stopBroadcast();
        // Creating a JSON array of input token addresses
        string memory inputs = string(
            abi.encodePacked(
                '["',
                addressToString.toAsciiString(address(mockInputTokenBurnable)),
                '", "',
                addressToString.toAsciiString(
                    address(mockInputTokenNonBurnable)
                ),
                '", "',
                addressToString.toAsciiString(address(SCX)),
                '", "',
                addressToString.toAsciiString(address(PyroSCX_EYE)),
                '"]'
            )
        );

        // Constructing the full JSON output
        string memory jsonOutput = string(
            abi.encodePacked(
                '{"Coupon":"',
                addressToString.toAsciiString(address(flax)),
                '", "Issuer":"',
                addressToString.toAsciiString(address(issuer)),
                '", "Multicall3":"',
                addressToString.toAsciiString(address(multicall3)),
                '", "HedgeyAdapter":"',
                addressToString.toAsciiString(address(hedgeyAdapter)),
                  '", "TilterFactory":"',
                addressToString.toAsciiString(address(tilterFactory)),
                  '", "EthTilter":"',
                addressToString.toAsciiString(address(ethTilter)),
                '", "msgsender":"',
                addressToString.toAsciiString(msg.sender),
                '", "Inputs":',
                inputs,
                "}"
            )
        );

        console.log(jsonOutput);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

contract AddressToString {
    // Helper function to convert address to string
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}