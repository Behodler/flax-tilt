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
    TokenLockupPlans tokenLockupPlan;

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
        tokenLockupPlan = new TokenLockupPlans("Hedge", "HDG");
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
        tilter = new Tilter(address(flax), address(router));
        tilter.configure(
            address(referenceToken),
            address(flax),
            address(oracle),
            address(bonfire)
        );
        flax.setMinter(address(tilter), true);

        vm.prank(tilterUser);
        flax.approve(address(tilter), 1000000 ether);
        vm.stopPrank();
        //END TILTER SETUP
    }

    function test_setup_works() public view {}

    function test_works_with_eth() public {
        //trade weth
        factory().createPair(address(flax), address(WETH()));
        referencePair = IUniswapV2Pair(
            factory().getPair(address(flax), address(WETH()))
        );

        //REGISTER PAIR ON BONFIRE
        bonfire.setTokenInfo(address(referencePair), true, false, 11574074);
        //END REGISTER PAIR ON BONFIRE

        //set up issuer
        tilter.configure(
            address(WETH()),
            address(flax),
            address(oracle),
            address(bonfire)
        );

        flax.mint(1 ether, address(referencePair));
        vm.deal(address(this), 100 ether);
        WETH().deposit{value: 10 ether}();
        WETH().transfer(address(referencePair), 2 ether);

        referencePair.mint(address(this));

        address[] memory path = new address[](2);
        path[0] = address(WETH());
        path[1] = address(flax);

        uint tradeAmount = (1 ether) / 20;
        uint flaxOut = router.getAmountOut(tradeAmount, 2 ether, 1 ether);

        router.swapETHForExactTokens{value: tradeAmount}(
            flaxOut,
            path,
            contractOwner,
            type(uint).max
        );

        //register oracle and bonfire
        oracle.RegisterPair(address(referencePair), 1);

        //trade some more

        (uint wethReserve, uint flaxReserve) = orderReserves(
            referencePair,
            address(WETH()),
            address(flax)
        );

        tradeAmount = 1e17;
        flaxOut = router.getAmountOut(tradeAmount, wethReserve, flaxReserve);

        router.swapETHForExactTokens{value: tradeAmount}(
            flaxOut,
            path,
            contractOwner,
            type(uint).max
        );

        // //update oracle
        vm.warp(block.timestamp + 61 minutes);
        vm.roll(block.number + 1);
        oracle.update(address(WETH()), address(flax));

        // tilter.issue
        vm.warp(block.timestamp + 61 minutes);
        vm.roll(block.number + 1);

        // PASSES TO HERE

        tilter.issue{value: 1 ether}(address(WETH()), 1 ether, tilterUser);

        uint flaxBalanceBeforeRedeem = flax.balanceOf(tilterUser);
        vm.warp(90 days);
        vm.roll(block.number + 10);
        vm.prank(tilterUser);
        tokenLockupPlan.redeemAllPlans();
        vm.stopPrank();
        uint flaxBalanceAfterRedeem = flax.balanceOf(tilterUser);

        vm.assertGt(flaxBalanceAfterRedeem - flaxBalanceBeforeRedeem, 0);
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

    function test_ref_value_of_tilt_matches_reality(
        uint purchaseAmount
    ) public {
        vm.assume(purchaseAmount > 1e17 && purchaseAmount < 1e18 / 2);
        //first a bit of trade
        address[] memory path = new address[](2);
        path[0] = address(referenceToken);
        path[1] = address(flax);

        uint tradeAmount = 2 << 57;
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

        uint refBalanceBefore = referenceToken.balanceOf(
            address(referencePair)
        );

        uint flaxBalanceBefore = flax.balanceOf(address(referencePair));

        uint refPerFlax_before_projection = (refBalanceBefore * 1e24) /
            flaxBalanceBefore;

        (uint flax_balance_on_lp_forecast, uint lpTokens_created) = tilter
            .refValueOfTilt(purchaseAmount, true);

        uint projected_ref_balance = refBalanceBefore + purchaseAmount;

        uint refPerFlax_after_projection = (projected_ref_balance * 1e24) /
            flax_balance_on_lp_forecast;

        //assert price rise projection
        vm.assertGt(refPerFlax_after_projection, refPerFlax_before_projection);
        vm.assertGt(lpTokens_created, 0);

        //this should not revert.
        tilter.refValueOfTilt(purchaseAmount, false);

        //jump ahead another half hour
        vm.warp(block.timestamp + 1 days + 30 minutes);
        vm.roll(block.number + 1);
        // oracle.update(address(flax), address(referenceToken));

        //mint and assert result equals refValue
        vm.prank(tilterUser);
        referenceToken.approve(address(tilter), 1000000 ether);
        vm.stopPrank();

        uint flaxPerRefBefore = oracle.safeConsult(
            address(referenceToken),
            address(flax),
            1e10
        );
        vm.prank(tilterUser);
        tilter.issue(address(referenceToken), purchaseAmount, tilterUser);
        vm.stopPrank();

        uint flax_balance_lp_after_actual_tilt = flax.balanceOf(
            address(referencePair)
        );
        uint ref_balance_lp_after_actual_tilt = referenceToken.balanceOf(
            address(referencePair)
        );

        vm.warp(block.timestamp + 10 minutes);
        vm.roll(block.number + 1);
        (uint flax_new_balance, ) = tilter.refValueOfTilt(purchaseAmount, true);

        uint flaxPerRefAfter = oracle.safeConsult(
            address(referenceToken),
            address(flax),
            1e10
        );

        uint assertionChoice = 100;
        // assertionChoice = vm.envUint("ASS");

        //1

        if (assertionChoice == 1 || assertionChoice == 100) {
            vm.assertGt(flaxPerRefBefore, 0);
            vm.assertGt(flaxPerRefAfter, 0);
            vm.assertGt(flaxPerRefBefore, flaxPerRefAfter);
            assertionChoice--;
        }

        //2
        if (assertionChoice == 2 || assertionChoice == 100) {
            vm.assertGt(flax_balance_lp_after_actual_tilt, flaxBalanceBefore);
            assertionChoice--;
        }

        //3
        if (assertionChoice == 3 || assertionChoice == 100) {
            uint quotient = flax_balance_lp_after_actual_tilt >
                flax_balance_on_lp_forecast
                ? (flax_balance_lp_after_actual_tilt * 1000) /
                    flax_balance_on_lp_forecast
                : (flax_balance_on_lp_forecast * 1000) /
                    flax_balance_on_lp_forecast;
            vm.assertGt(quotient, 998);
            assertionChoice--;
        }

        //4
        if (assertionChoice == 4 || assertionChoice == 100) {
            vm.assertEq(
                ref_balance_lp_after_actual_tilt,
                projected_ref_balance
            );
            assertionChoice--;
        }
    }

    function orderReserves(
        IUniswapV2Pair pair,
        address token0,
        address token1
    ) private view returns (uint reserveA, uint reserveB) {
        (token0, token1) = token0 < token1
            ? (token0, token1)
            : (token1, token0);

        (uint reserve0, uint reserve1, ) = pair.getReserves();

        if (token0 == token0) {
            reserveA = reserve0;
            reserveB = reserve1;
        } else {
            reserveA = reserve1;
            reserveB = reserve0;
        }
    }
}
