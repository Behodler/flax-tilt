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
import "../src/TilterFactory.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract Factory is Test {
    Coupon flax;
    Issuer issuer;
    UniswapV2Router02 router;
    Oracle oracle;
    TilterFactory tilterFactory;
    HedgeyAdapter stream;

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function setUp() public {
        //setup FLAX
        flax = new Coupon("Flax", "flx");
        flax.setMinter(address(this), true);
        //SETUP HEDGEY
        TokenLockupPlans tokenLockup = new TokenLockupPlans("HED", "hdg");
        stream = new HedgeyAdapter(address(flax), address(tokenLockup));

        //setup BONFIRE
        issuer = new Issuer(address(flax), address(stream));
        issuer.setLimits(1000, 2, 10, 4);

        //SETUP UNISWAP
        router = new UniswapV2Router02(
            address(new UniswapV2Factory(address(this))),
            address(new WETH9())
        );
        //SETUP ORACLE
        oracle = new Oracle(address(factory()));
        tilterFactory = new TilterFactory(
            address(router),
            address(flax),
            address(oracle),
            address(issuer)
        );
    }

    function test_setup() public {}

    function test_deploy() public {
        //Deploy to new Ref Token
        address referenceToken = address(new MockToken("REF", "REF"));
        factory().createPair(address(flax), address(referenceToken));
        address referencePair = factory().getPair(
            address(flax),
            address(referenceToken)
        );
        MockToken(referenceToken).mint(referencePair, 10 ether);
        flax.mint(10 ether, referencePair);
        IUniswapV2Pair(referencePair).mint(address(this));

        //ORACLE REGISTER REFERENCE PAIR
        oracle.RegisterPair(referencePair, 1 hours);

        address existingTilter = tilterFactory.tiltersByRef(referenceToken);
        vm.assertEq(existingTilter, address(0));

        tilterFactory.deploy(referenceToken);

        address newTilter = tilterFactory.tiltersByRef(referenceToken);
        address refByTilt = tilterFactory.refByTilter(newTilter);

        vm.assertNotEq(newTilter, address(0));
        vm.assertEq(refByTilt, referenceToken);

        (
            address _ref,
            IUniswapV2Factory _factory,
            IUniswapV2Router02 _router,
            address _flax,
            ,
            address _issuer
        ) = Tilter(newTilter).VARS();

        bool correctlyAssigned = _ref == referenceToken &&
            _factory == factory() &&
            _router == router &&
            _flax == address(flax) &&
            _issuer == address(issuer);

        vm.assertTrue(correctlyAssigned);

        //Redeploy to same ref token fails
        vm.expectRevert(
            abi.encodeWithSelector(
                RefTokenTaken.selector,
                referenceToken,
                newTilter
            )
        );
        tilterFactory.deploy(referenceToken);
    }

    function test_configure() public {
        //Deploy to new Ref Token
        address referenceToken = address(new MockToken("REF", "REF"));
        factory().createPair(address(flax), address(referenceToken));
        address referencePair = factory().getPair(
            address(flax),
            address(referenceToken)
        );
        MockToken(referenceToken).mint(referencePair, 10 ether);
        flax.mint(10 ether, referencePair);
        IUniswapV2Pair(referencePair).mint(address(this));

        //ORACLE REGISTER REFERENCE PAIR
        oracle.RegisterPair(referencePair, 1 hours);

        address existingTilter = tilterFactory.tiltersByRef(referenceToken);
        vm.assertEq(existingTilter, address(0));

        tilterFactory.deploy(referenceToken);

        address newTilter = tilterFactory.tiltersByRef(referenceToken);
        Coupon newFLX = new Coupon("New Flax", "NEW");
        Oracle newOracle = new Oracle(address(factory()));
        factory().createPair(address(newFLX), address(referenceToken));
        newFLX.setMinter(address(this), true);
        address newRefPair = factory().getPair(
            address(newFLX),
            address(referenceToken)
        );
        newFLX.mint(10 ether, newRefPair);
        MockToken(referenceToken).mint(newRefPair, 10 ether);
        IUniswapV2Pair(newRefPair).mint(address(this));
        newOracle.RegisterPair(newRefPair, 1 hours);
        Issuer newIssuer = new Issuer(address(newFLX), address(stream));
        tilterFactory.configure(
            newTilter,
            address(newFLX),
            address(newOracle),
            address(newIssuer)
        );
        address someAddress = address(0x1);
        vm.expectRevert(
            abi.encodeWithSelector(TilterNotMapped.selector, someAddress)
        );
        tilterFactory.configure(
            someAddress,
            address(newFLX),
            address(newOracle),
            address(newIssuer)
        );
    }

    function test_adopt_and_abandon_tilter() public {
        //Deploy to new Ref Token
        address referenceToken = address(new MockToken("REF", "REF"));
        factory().createPair(address(flax), address(referenceToken));
        address referencePair = factory().getPair(
            address(flax),
            address(referenceToken)
        );
        MockToken(referenceToken).mint(referencePair, 10 ether);
        flax.mint(10 ether, referencePair);
        IUniswapV2Pair(referencePair).mint(address(this));

        //ORACLE REGISTER REFERENCE PAIR
        oracle.RegisterPair(referencePair, 1 hours);

        address existingTilter = tilterFactory.tiltersByRef(referenceToken);
        vm.assertEq(existingTilter, address(0));

        tilterFactory.deploy(referenceToken);

        Tilter newTilter = Tilter(tilterFactory.tiltersByRef(referenceToken));

        vm.assertEq(newTilter.owner(), address(tilterFactory));
        tilterFactory.abandonTilter(address(newTilter));

        vm.assertEq(newTilter.owner(), address(this));
        address referenceByTilter = tilterFactory.refByTilter(
            address(newTilter)
        );
        address tilterByReference = tilterFactory.tiltersByRef(
            address(referenceToken)
        );

        bool nullified = referenceByTilter == tilterByReference &&
            referenceByTilter == address(0);
        vm.assertTrue(nullified);

        //Forget to transfer to tilterFactory
        vm.expectRevert(
            abi.encodeWithSelector(
                AdoptionRequiresOwnershipTransfer.selector,
                address(this)
            )
        );
        tilterFactory.adoptOrphanTilter(address(newTilter));

        newTilter.transferOwnership(address(tilterFactory));
        tilterFactory.adoptOrphanTilter(address(newTilter));
        uint upTo = 5;
        // upTo = vm.envUint("UPTO");

        referenceByTilter = tilterFactory.refByTilter(address(newTilter));
        tilterByReference = tilterFactory.tiltersByRef(address(referenceToken));
        vm.assertEq(tilterByReference, address(newTilter));
        vm.assertEq(referenceByTilter, referenceToken);
        if (upTo == 0) return;

        tilterFactory.adoptOrphanTilter(address(newTilter));

        //assert nothing happens
        referenceByTilter = tilterFactory.refByTilter(address(newTilter));
        tilterByReference = tilterFactory.tiltersByRef(address(referenceToken));
        vm.assertEq(tilterByReference, address(newTilter));
        vm.assertEq(referenceByTilter, referenceToken);
        if (upTo == 1) return;

        Tilter brandNewTilter = new Tilter(address(flax), address(router));
        brandNewTilter.configure(
            address(referenceToken),
            address(flax),
            address(oracle),
            address(issuer)
        );
        brandNewTilter.transferOwnership(address(tilterFactory));

        //test ownership reverted
        tilterFactory.adoptOrphanTilter(address(brandNewTilter));
        address owner = tilterFactory.owner();
        if (upTo == 2) return;

        vm.assertEq(owner, address(this));

        tilterByReference = tilterFactory.tiltersByRef(address(referenceToken));
        referenceByTilter = tilterFactory.refByTilter(address(brandNewTilter));
        if (upTo == 3) return;

        vm.assertNotEq(tilterByReference, address(brandNewTilter));
        vm.assertEq(tilterByReference, address(newTilter));
        vm.assertEq(referenceByTilter, address(0));
        referenceByTilter = tilterFactory.refByTilter(address(newTilter));

        vm.assertEq(referenceByTilter, address(referenceToken));
        if (upTo == 4) return;

        //don't transfer ownership should revert
        vm.expectRevert(
            abi.encodeWithSelector(
                RefTokenTaken.selector,
                address(referenceToken),
                address(newTilter)
            )
        );
        tilterFactory.adoptOrphanTilter(address(brandNewTilter));
    }

    function test_access_control() public {
        address someSchmuck = address(0x3);
        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.adoptOrphanTilter(address(0x10));
        vm.stopPrank();

        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.abandonTilter(address(0x10));
        vm.stopPrank();

        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.deploy(address(0x10));
        vm.stopPrank();

        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.configure(
            address(0x10),
            address(0x10),
            address(0x10),
            address(0x10)
        );
        vm.stopPrank();

        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.setOracle(address(0x10));
        vm.stopPrank();
        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.setIssuer(address(0x10));
        vm.stopPrank();

        vm.prank(someSchmuck);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                someSchmuck
            )
        );
        tilterFactory.setEnabled(address(0x10), false);
        vm.stopPrank();
    }
}
