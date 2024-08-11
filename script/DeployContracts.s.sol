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

        Coupon shiba = new Coupon("Shiba", "Inu");
        Coupon uniGov = new Coupon("UNI", "UNI");

        shiba.setMinter(msg.sender, true);
        uniGov.setMinter(msg.sender, true);

        shiba.mint(2000 ether, msg.sender);
        uniGov.mint(3000 ether, msg.sender);

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

        //create pairs
        WETH().deposit{value: 1 ether}();
        IUniswapV2Pair flx_weth_pair = createFlaxPair(
            address(flax),
            address(WETH())
        );

        // TODO: Break into multiple scripts :(
        IUniswapV2Pair flx_shib_pair = createFlaxPair(
            address(flax),
            address(shiba)
        );

        IUniswapV2Pair flx_uni_pair = createFlaxPair(
            address(flax),
            address(uniGov)
        );

        // trade a little
        sellFlax(address(flax), address(WETH()), true);
        sellFlax(address(flax), address(shiba), false);
        sellFlax(address(flax), address(uniGov), false);

        //CREATE ORACLE
        Oracle oracle = new Oracle(address(factory()));

        //ORACLE REGISTER PAIR
        oracle.RegisterPair(address(flx_weth_pair), 30);
        oracle.RegisterPair(address(flx_shib_pair), 30);
        oracle.RegisterPair(address(flx_uni_pair), 30);

        //ISSUER REGISTER PAIR
        issuer.setTokenInfo(address(flx_weth_pair), true, false, 11574074);
        issuer.setTokenInfo(address(flx_shib_pair), true, false, 13574074);
        issuer.setTokenInfo(address(flx_uni_pair), true, false, 10574074);

        //Deploy TilterFactory
        TilterFactory tilterFactory = new TilterFactory(
            address(router),
            address(flax),
            address(oracle),
            address(issuer)
        );
        tilterFactory.deploy(address(WETH()));
        //HYPOTHESIS: script too big
        tilterFactory.deploy(address(shiba));
        tilterFactory.deploy(address(uniGov));

        address ethTilterAddress = tilterFactory.getEthTilter();
        address shibTilter = tilterFactory.tiltersByRef(address(shiba));
        address uniTilter = tilterFactory.tiltersByRef(address(uniGov));

        require(shibTilter != address(0), "shib not created");
        require(uniTilter != address(0), "uniTilter not created");

        flax.setMinter(ethTilterAddress, true);
        flax.setMinter(shibTilter, true);
        flax.setMinter(uniTilter, true);

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
                addressToString.toAsciiString(address(WETH())),
                '", "',
                addressToString.toAsciiString(address(PyroSCX_EYE)),
                '", "',
                addressToString.toAsciiString(address(shiba)),
                '", "',
                addressToString.toAsciiString(address(uniGov)),
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
                '", "UniswapV2Router":"',
                addressToString.toAsciiString(address(router)),
                '", "TilterFactory":"',
                addressToString.toAsciiString(address(tilterFactory)),
                '", "Oracle":"',
                addressToString.toAsciiString(address(oracle)),
                '", "Weth":"',
                addressToString.toAsciiString(address(WETH())),
                '", "EthTilter":"',
                addressToString.toAsciiString(address(ethTilterAddress)),
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

    function createFlaxPair(
        address flax,
        address token
    ) private returns (IUniswapV2Pair) {
        factory().createPair(token, flax);
        IUniswapV2Pair pair = IUniswapV2Pair(factory().getPair(token, flax));
        Coupon(token).transfer(address(pair), 1 ether);
        Coupon(flax).mint(10 ether, address(pair));
        pair.mint(msg.sender);
        return pair;
    }

    function sellFlax(
        address flaxAddress,
        address ouputputToken,
        bool eth
    ) private {
        Coupon flax = Coupon(flaxAddress);
        flax.mint(10 ether, msg.sender);
        address pairAddress = factory().getPair(flaxAddress, ouputputToken);

        address[] memory path = new address[](2);
        path[0] = flaxAddress;
        path[1] = ouputputToken;

        uint tradeAmount = (1 ether) / 20;

        uint flaxReserve = flax.balanceOf(pairAddress);
        uint ouputReserve = Coupon(ouputputToken).balanceOf(pairAddress);

        uint outAmount = router.getAmountOut(
            tradeAmount,
            flaxReserve,
            ouputReserve
        );
        flax.approve(address(router), type(uint).max);

        if (eth) {
            router.swapExactTokensForETH(
                tradeAmount,
                outAmount,
                path,
                msg.sender,
                type(uint).max
            );
        } else {
            router.swapExactTokensForTokens(
                tradeAmount,
                outAmount,
                path,
                msg.sender,
                type(uint).max
            );
        }
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
