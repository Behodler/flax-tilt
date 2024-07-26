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

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract TilterTest is Test {
    MockToken referenceToken;
    Coupon flax;
    address contractOwner = address(0x1);
    address tilterUser = address(0x2);

    Issuer bonfire;
    UniswapV2Router02 router;
    IUniswapV2Pair referencePair;
    Oracle oracle;
    Tilter tilter;

    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    function setUp() public {
        //SETUP BONFIRE
        referenceToken = new MockToken("Reference", "REF20");
        flax = new Coupon("Flax", "FLX");
        TokenLockupPlans tokenLockupPlan = new TokenLockupPlans("Hedge", "HDG");
        HedgeyAdapter hedgeyAdapter = new HedgeyAdapter(
            address(flax),
            address(tokenLockupPlan)
        );
        bonfire = new Issuer(address(flax), address(hedgeyAdapter));
        flax.setMinter(address(bonfire), true);

        bonfire.setLimits(10000, 60, 1, 1);
        //END BONFIRE SETUP

        //SETUP UNISWAP PAIR AND ORACLE
        router = new UniswapV2Router02(
            address(new UniswapV2Factory(contractOwner)),
            address(new WETH9())
        );

        factory().createPair(address(flax), address(referenceToken));
        referencePair = IUniswapV2Pair(
            factory().getPair(address(flax), address(referenceToken))
        );
        flax.setMinter(address(this), true);
        flax.mint(10 ether, address(referencePair));
        referenceToken.mint(address(referencePair), 10 ether);
        //mint pair liquidity
        referencePair.mint(contractOwner);

        //mint trader liquidity
        flax.mint(100 ether, tilterUser);
        referenceToken.mint(tilterUser, 100 ether);

        vm.prank(tilterUser);
        flax.approve(address(router), 1000000 ether);
        vm.stopPrank();

        vm.prank(tilterUser);
        referenceToken.approve(address(router), 100000 ether);
        vm.stopPrank();

        address[] memory path = new address[](2);
        path[0] = address(referenceToken);
        path[1] = address(flax);

        uint tradeAmount = (1 ether) / 10;
        uint flaxOut = router.getAmountOut(tradeAmount, 10 ether, 10 ether);

        //passing up to here
        vm.prank(tilterUser);
        router.swapExactTokensForTokens(
            tradeAmount,
            flaxOut,
            path,
            contractOwner,
            type(uint).max
        );
        vm.stopPrank();

        oracle = new Oracle(address(factory()));
        oracle.RegisterPair(address(referencePair), 1);

        uint flaxReserve = flax.balanceOf(address(referencePair));
        uint referenceReserve = referenceToken.balanceOf(
            address(referencePair)
        );

        uint refOut = router.getAmountOut(
            tradeAmount,
            referenceReserve,
            flaxReserve
        );

        path[0] = address(flax);
        path[1] = address(referenceToken);

        vm.prank(tilterUser);
        router.swapExactTokensForTokens(
            tradeAmount,
            refOut,
            path,
            contractOwner,
            type(uint).max
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 61 * 60);
        vm.roll(block.number + 1);

        oracle.update(address(referenceToken), address(flax));
        // END UNI SETUP

        //REGISTER PAIR ON BONFIRE
        bonfire.setTokenInfo(address(referencePair), true, false, 11574074);
        //END REGISTER PAIR ON BONFIRE

        //SETUP TILTER
        tilter = new Tilter(address(flax));
        tilter.configure(
            address(referenceToken),
            address(flax),
            address(oracle),
            address(bonfire)
        );
        oracle.setUpdater(address(tilter), true);
        flax.setMinter(address(tilter), true);

        //END TILTER SETUP
    }

    function test_setup_works() public view {}

    function test_works_with_eth() public view {
        require(3 > 4, "NOT IMPLEMENTED");
    }

    function test_disable_tilter() public {
        tilter.setEnabled(false);
        vm.expectRevert(
            abi.encodeWithSelector(TitlerHasBeenDisabledByOwner.selector)
        );
        tilter.issue(address(referenceToken), 1 ether, tilterUser);
    }

    function test_use_incorrect_token_fails() public {
        MockToken someToken = new MockToken("Wrong", "One");
        vm.expectRevert(
            abi.encodeWithSelector(
                InputTokenMismatch.selector,
                address(someToken),
                address(referenceToken)
            )
        );
        tilter.issue(address(someToken), 1 ether, tilterUser);
    }

    function test_ownable_access_control() public {
        vm.startPrank(tilterUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                tilterUser
            )
        );
        tilter.configure(
            address(referenceToken),
            address(flax),
            address(oracle),
            address(bonfire)
        );
        vm.stopPrank();
    }

    function test_ref_value_of_tilt_matches_reality() public {
        //first a bit of trade
        address[] memory path = new address[](2);
        path[0] = address(referenceToken);
        path[1] = address(flax);

        uint tradeAmount = (1 ether) / 10;
        uint flaxOut = router.getAmountOut(tradeAmount, 10 ether, 10 ether);

        //passing up to here
        vm.prank(tilterUser);
        router.swapExactTokensForTokens(
            tradeAmount,
            flaxOut,
            path,
            contractOwner,
            type(uint).max
        );
        vm.stopPrank();

        //jump ahead by half hour
        vm.warp(block.timestamp + 30 minutes);
        vm.roll(block.number + 1);

        //get refValue with preview
        uint refBalanceBefore = referenceToken.balanceOf(
            address(referencePair)
        );

        uint flaxBalanceBefore = flax.balanceOf(address(referencePair));

        uint refPerFlax_before_projection = (refBalanceBefore * 1e20) /
            flaxBalanceBefore;

        (uint flax_balance_forecast, uint lpTokens_created) = tilter
            .refValueOfTilt(1 ether, true);

        uint projected_ref_balance = refBalanceBefore + 1 ether;

        uint refPerFlax_after_projection = (projected_ref_balance * 1e20) /
            flax_balance_forecast;

        //assert price rise projection
        vm.assertGt(refPerFlax_after_projection, refPerFlax_before_projection);
        vm.assertGt(lpTokens_created, 0);

        vm.expectRevert(
            abi.encodeWithSelector(WaitPeriodTooSmall.selector, 1800, 3600)
        );
        tilter.refValueOfTilt(1 ether, false);

        //jump ahead another half hour
        vm.warp(block.timestamp + 30 minutes);
        vm.roll(block.number + 1);
        // oracle.update(address(flax), address(referenceToken));

        //mint and assert result equals refValue
        vm.prank(tilterUser);
        referenceToken.approve(address(tilter), 1000000 ether);
        vm.stopPrank();

        uint flaxPerRefBefore = oracle.consult(
            address(referenceToken),
            address(flax),
            1e10,
            true
        );

        vm.prank(tilterUser);
        tilter.issue(address(referenceToken), 1 ether, tilterUser);
        vm.stopPrank();

        uint flax_balance_lp_after_actual_tilt = flax.balanceOf(
            address(referencePair)
        );
        uint ref_balance_lp_after_actual_tilt = referenceToken.balanceOf(
            address(referencePair)
        );

        vm.warp(block.timestamp + 10 minutes);
        vm.roll(block.number + 1);
        uint flaxPerRefAfter = oracle.consult(
            address(referenceToken),
            address(flax),
            1e10,
            true
        );

        vm.assertGt(flaxPerRefBefore, flaxPerRefAfter);
        vm.assertGt(flax_balance_lp_after_actual_tilt, flaxBalanceBefore);
        vm.assertEq(flax_balance_lp_after_actual_tilt, flax_balance_forecast);
        vm.assertEq(ref_balance_lp_after_actual_tilt, projected_ref_balance);
    }
}