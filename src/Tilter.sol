// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import {IERC20} from "@oz_tilt/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@oz_tilt/contracts/utils/ReentrancyGuard.sol";
import "@behodler/flax/IIssuer.sol";
import {ICoupon} from "@behodler/flax/ICoupon.sol";
import {Issuer} from "@behodler/flax/Issuer.sol";
import "./ITilter.sol";
import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "./Oracle.sol";
import "./Errors.sol";
import "./IWeth.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";
import "@uniswap/core/libraries/Math.sol";

///@author Justin Goro
/**@notice In order to re-use audited code, the UniswapHelper is copied from Limbo
 * to function as the price tilting contract for Flax.
 */
/*Ownable,*/ contract Tilter is Ownable,ReentrancyGuard, ITilter {
    uint256 constant SPOT = 1e10;
    bool _enabled;

    struct MintEstimationVariables {
        address token0;
        address token1;
        uint balance0;
        uint balance1;
        uint reserve0;
        uint reserve1;
        uint amount0;
        uint amount1;
    }

    UniVARS public VARS;

    constructor(address flx, address uniRouter) Ownable(msg.sender) {
        VARS.router = IUniswapV2Router02(uniRouter);
        VARS.flax = flx;
        _enabled = true;
    }

    function setEnabled(bool enabled) external onlyOwner {
        _enabled = enabled;
    }

    function configure(
        address ref_token,
        address flx,
        address oracle,
        address issuer
    ) external onlyOwner {
        VARS.ref_token = ref_token;
        VARS.flax = flx;

        Oracle limboOracle = Oracle(oracle);
        VARS.factory = limboOracle.factory();

        address flx_ref_token = VARS.factory.getPair(flx, ref_token);
        address zero = address(0);

        if (flx_ref_token == zero) {
            revert OracleLPsNotSet(flx_ref_token);
        }

        VARS.oracleSet = OracleSet({
            oracle: limboOracle,
            flx_ref_token: IUniswapV2Pair(flx_ref_token)
        });

        //tokens differ in how they approach this situation.
        IERC20(flx).approve(address(this), type(uint).max);

        IERC20(flx_ref_token).approve(issuer, type(uint).max);
        VARS.issuer = issuer;
    }

    //preview allows the caller to simulate a call to update before retrieving the value.
    //This is useful for clients which wish to
    //report accurate data to end users without spending gas. Never set preview to true during a transaction.
    function refValueOfTilt(
        uint ref_amount,
        bool preview
    ) external view returns (uint flax_new_balance, uint lpTokens_created) {
        uint flaxPerRef = consultFlaxPerRef(preview);
        uint flx_amount = (ref_amount * flaxPerRef * 6) / (10 * SPOT);

        MintEstimationVariables memory mint_vars;

        uint totalSupply = VARS.oracleSet.flx_ref_token.totalSupply();
        (mint_vars.token0, mint_vars.token1) = UniswapV2Library.sortTokens(
            VARS.flax,
            VARS.ref_token
        );

        address pair_address = VARS.factory.getPair(
            mint_vars.token0,
            mint_vars.token1
        );
        (mint_vars.reserve0, mint_vars.reserve1) = UniswapV2Library.getReserves(
            address(VARS.factory),
            mint_vars.token0,
            mint_vars.token1
        );

        mint_vars.balance0 = IERC20(mint_vars.token0).balanceOf(pair_address);
        mint_vars.balance1 = IERC20(mint_vars.token1).balanceOf(pair_address);
        if (mint_vars.token0 == VARS.flax) {
            mint_vars.balance0 += flx_amount;
            mint_vars.balance1 += ref_amount;
            flax_new_balance = mint_vars.balance0;
        } else {
            mint_vars.balance1 += flx_amount;
            mint_vars.balance0 += ref_amount;
            flax_new_balance = mint_vars.balance1;
        }

        mint_vars.amount0 = mint_vars.balance0 - mint_vars.reserve0;
        mint_vars.amount1 = mint_vars.balance1 - mint_vars.reserve1;

        lpTokens_created = Math.min(
            (mint_vars.amount0 * totalSupply) / mint_vars.reserve0,
            (mint_vars.amount1 * totalSupply) / mint_vars.reserve1
        );
    }

    function issue(
        address inputToken,
        uint amount,
        address recipient
    ) external payable nonReentrant {
        if (inputToken != VARS.ref_token)
            revert InputTokenMismatch(inputToken, VARS.ref_token);
        if (!_enabled) {
            revert TitlerHasBeenDisabledByOwner();
        }
        if (msg.value > 0) {
            address wethAddress = VARS.router.WETH();
            require(
                inputToken == wethAddress,
                "Sending Eth to non Eth price-tilter"
            );
            IWETH(VARS.ref_token).deposit{value: msg.value}();
        } else {
            IERC20(inputToken).transferFrom(msg.sender, address(this), amount);
        }
        _issue(amount, recipient);
    }

    function consultFlaxPerRef(bool unsafe) internal view returns (uint) {
        if (unsafe)
            return
                VARS.oracleSet.oracle.unsafeConsult(
                    VARS.ref_token,
                    VARS.flax,
                    SPOT
                );
        else {
            return
                VARS.oracleSet.oracle.safeConsult(
                    VARS.ref_token,
                    VARS.flax,
                    SPOT
                );
        }
    }

    //function renamed from generateFLNQuote
    function generateFLXQuote() internal returns (bool preview) {
        OracleSet memory set = VARS.oracleSet;
        Oracle oracle = set.oracle;
        UniVARS memory localVARS = VARS;

        (uint32 blockTimeStamp, uint256 period) = oracle.getLastUpdate(
            localVARS.flax,
            localVARS.ref_token
        );
        if (block.timestamp - blockTimeStamp >= period) {
            preview = true;
            set.oracle.update(localVARS.ref_token, localVARS.flax);
        }
    }

    function _issue(uint amount, address recipient) private {
        //SECURITY VALIDATIONS

        //UPDATE ORACLE
        generateFLXQuote();
        uint flaxPerRef = consultFlaxPerRef(false);
        //END ORACLE UPDATE

        //TILT PRICE IN FAVOUR OF FLAX
        //tilt by 60%
        uint flxToMint = (amount * flaxPerRef * 6) / (10 * SPOT);

        ICoupon(VARS.flax).mint(
            flxToMint,
            address(VARS.oracleSet.flx_ref_token)
        );

        IERC20(VARS.ref_token).transfer(
            address(VARS.oracleSet.flx_ref_token),
            amount
        );

        VARS.oracleSet.flx_ref_token.mint(address(this));
        uint mintedLP = VARS.oracleSet.flx_ref_token.balanceOf(address(this));
        // END PRICE TILTING

        // DEPOSIT TO BONFIRE
        Issuer(VARS.issuer).issue(
            address(VARS.oracleSet.flx_ref_token),
            mintedLP,
            recipient
        );
        //DEPOSIT TO BONFIRE
    }

    function WETH() private returns (IWETH) {
        return IWETH(IUniswapV2Router02(VARS.router).WETH());
    }

    function factory() private returns (IUniswapV2Factory) {
        return IUniswapV2Factory(IUniswapV2Router02(VARS.router).factory());
    }
}
