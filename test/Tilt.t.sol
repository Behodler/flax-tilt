
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {Coupon} from "@behodler/flax/Coupon.sol";
contract Tilt is Test {
    Coupon flax;
    
    function setUp() public {
        /*TODO:
        1. Deploy Flx
        2. Deploy WETH
        3. Fork UniswapV2 core and periphery if not already done. Change their versions to 0.8.20 set their imports to non conflicting
        3. Install both as libs, setting remote origin to Behodler and not Uniswap
        3. Deploy Uniswap
        4. Create a pair of FLX/WETH
        5. Trade once on pair
        6. Create an oracle of the pair.
        7. Trade a few more time and update the pair
        8. Instantiate TokenLockupPlan
        */
       flax = new Coupon("Flax","FLX");
       flax.setMinter(address(this),true);
    }

    /* Tests TODO:
    1. test invalid inputs such as incorrect duraiton choice
    2. test tilt with no preloaded FLX
    3. test that, for a given price of FLX in Eth, sending in x Eth requires exactly 2x ETH worth of FLX.
    4. test for each choice that the lockup is the correct duration, that the price and the tilted correctly.
    5. Time test to see that stream flows correctly.
    */
}