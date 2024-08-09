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

contract UpdateOracles is Script {
    function parseAddress(
        string memory _a
    ) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function run() public {
        vm.startBroadcast();

        address oracleAddress = vm.envAddress("UNIORACLE");

        address wethAddress = vm.envAddress("WETH");

        address flaxAddress = vm.envAddress("FLAX");

        Oracle oracle = Oracle(oracleAddress);

        oracle.update(wethAddress, flaxAddress);
        oracle.updatePeriod(wethAddress, flaxAddress, 1 hours);

        vm.stopBroadcast();
    }
}
