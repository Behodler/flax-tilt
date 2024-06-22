// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {Coupon} from "@behodler/flax/Coupon.sol";
import {UniswapV2Router02} from "@uniswap/periphery/UniswapV2Router02.sol";
import {WETH9} from "@uniswap/periphery/test/WETH9.sol";
import {UniswapV2Factory} from "@uniswap/core/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import {Oracle} from "src/Oracle.sol";
import {TokenLockupPlans} from "@hedgey/lockup/TokenLockupPlans.sol";
import {HedgeyAdapter} from "src/HedgeyAdapter.sol";
import {UniswapHelper} from "src/UniswapHelper.sol";
import {IERC20} from "@oz_tilt/contracts/token/ERC20/IERC20.sol";
import "src/Errors.sol";

contract Tilt is Test {
    Coupon flax;
    UniswapV2Router02 router;
    IUniswapV2Pair flax_weth;
    address user1 = address(0x1);
    Oracle oracle;
    TokenLockupPlans hedgey;
    HedgeyAdapter hedgeyAdapter;
    UniswapHelper priceTilter;

    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    event amountOut(uint amount);

    function setUp() public {
        /*
        1. Deploy Flx
        2. Deploy WETH
        3. Fork UniswapV2 core and periphery if not already done. Change their versions to 0.8.20 set their imports to non conflicting
        3. Install both as libs, setting remote origin to Behodler and not Uniswap --DONE to this point
        3. Deploy Uniswap
        4. Create a pair of FLX/WETH
        5. Trade once on pair
        6. Create an oracle of the pair.
        7. Trade a few more time and update the pair
        8. Instantiate TokenLockupPlan
        */
        flax = new Coupon("Flax", "FLX");
        flax.setMinter(address(this), true);
        router = new UniswapV2Router02(
            address(new UniswapV2Factory(address(this))),
            address(new WETH9())
        );
        factory().createPair(address(flax), address(WETH()));
        address flx_weth_address = factory().getPair(
            address(flax),
            address(WETH())
        );
        require(flx_weth_address != address(0), "failed to initialize pair");
        flax_weth = IUniswapV2Pair(flx_weth_address);
        vm.deal(payable(address(this)), 300 ether);
        WETH().deposit{value: 3 ether}();
        flax.mint(200 ether, flx_weth_address);
        WETH().transfer(flx_weth_address, 3 ether);
        flax_weth.mint(address(this));

        require(flax_weth.totalSupply() > 0, "mint failed");
        require(flax.balanceOf(flx_weth_address) == 200 ether, "mint failed");
        require(WETH().balanceOf(flx_weth_address) == 3 ether, "mint failed");
        flax.mint(100 ether, address(this));

        uint wethOut = router.getAmountOut(30 ether, 200 ether, 3 ether);
        require(wethOut == 390283154277760862, "trade estimation failed");
        emit amountOut(wethOut);

        uint ethBalanceOfUserBefore = user1.balance;
        require(
            ethBalanceOfUserBefore == 0,
            "user1 should not have an initial balance "
        );
        address[] memory path = new address[](2);
        path[0] = address(flax);
        path[1] = address(WETH());
        flax.approve(address(router), 10000 ether);

        router.swapExactTokensForETH(
            30 ether,
            390283154277760862,
            path,
            user1,
            type(uint128).max
        );

        require(user1.balance == 390283154277760862, "swap unsuccessful");

        oracle = new Oracle(address(factory()));
        oracle.RegisterPair(flx_weth_address, 1);
        vm.warp(block.timestamp + 1 hours + 1);
        oracle.update(address(flax), address(WETH()));

        uint newReserveFlax = flax.balanceOf(flx_weth_address);
        uint newReserveWeth = WETH().balanceOf(flx_weth_address);

        wethOut = router.getAmountOut(30 ether, newReserveFlax, newReserveWeth);
        router.swapExactTokensForETH(
            30 ether,
            wethOut,
            path,
            user1,
            type(uint128).max
        );

        vm.warp(block.timestamp + 1 hours + 1);
        oracle.update(address(flax), address(WETH()));

        hedgey = new TokenLockupPlans("MrHedgey", "HEDGE");
        hedgeyAdapter = new HedgeyAdapter(address(flax), address(hedgey));
        priceTilter = new UniswapHelper(address(flax));
        priceTilter.configure(
            address(WETH()),
            address(flax),
            address(oracle),
            address(hedgeyAdapter)
        );
    }

    function testSetupWorked() public {}

    /* Tests TODO:
    1. test invalid inputs such as incorrect duraiton choice
    2. test tilt with no preloaded FLX
    3. test that, for a given price of FLX in Eth, sending in x Eth requires exactly 2x ETH worth of FLX.
    4. test for each choice that the lockup is the correct duration, that the price and the tilted correctly.
    5. Time test to see that stream flows correctly.
    */

    function testInvalidTermChoiceFails() public {
        vm.expectRevert(bytes("Invalid term duration"));
        priceTilter.tiltFlax{value: 3 ether}(6);
    }

    function testTooLittleEthFails() public {
        vm.expectRevert(bytes("Eth required"));
        priceTilter.tiltFlax{value: 999_999}(1);
    }

    event oracleFlaxValueOfEth(uint val);

    function test2xFlxDeduction() public {
        uint initialFlax = IERC20(address(flax)).balanceOf(
            address(priceTilter)
        );
        vm.assertEq(initialFlax, 0);
        uint ethToUse = (25 ether) / 10;
        uint SPOT = 1e8;
        uint flaxValueOfEth = (oracle.consult(
            address(WETH()),
            address(flax),
            SPOT
        ) * ethToUse) / SPOT;

        vm.assertGt(flaxValueOfEth, 0);
        emit oracleFlaxValueOfEth(flaxValueOfEth);
        //TODO: send in 2x - 1 and assert revert. Then send in 1 and assert success

        uint tiltUsedValue = flaxValueOfEth * 2;
        flax.mint(tiltUsedValue - 1, address(priceTilter));
        // vm.expectRevert(bytes("Tilter: insufficient FLX"));
        vm.deal(payable(address(user1)), 300 ether);
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientFlaxForTilting.selector,
                tiltUsedValue - 1,
                tiltUsedValue
            )
        );
        priceTilter.tiltFlax{value: ethToUse}(0);
        vm.stopPrank();

        flax.mint(1, address(priceTilter));
        vm.prank(user1);
        priceTilter.tiltFlax{value: ethToUse}(0);
        vm.stopPrank();
        //success
    }
}
