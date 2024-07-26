// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import {IERC20} from "@oz_tilt/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@oz_tilt/contracts/utils/ReentrancyGuard.sol";
import "@behodler/flax/IIssuer.sol";
import {ICoupon} from "@behodler/flax/ICoupon.sol";
import {Issuer} from "@behodler/flax/Issuer.sol";

import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "./LimboOracleLike.sol";
import "./Errors.sol";
import "./IWeth.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";
import "@uniswap/core/libraries/Math.sol";

///@author Justin Goro
/**@notice In order to re-use audited code, the UniswapHelper is copied from Limbo
 * to function as the price tilting contract for Flax.
 */
contract Tilter is
    Ownable,
    ReentrancyGuard
    //Explanation: governance is simple ownable
    /**is Governable, AMMHelper*/
{
    uint256 constant SPOT = 1e10;
    bool _enabled;

    struct OracleSet {
        IUniswapV2Pair flx_ref_token;
        LimboOracleLike oracle;
    }

    struct UniVARS {
        uint256 minQuoteWaitDuration;
        IUniswapV2Factory factory;
        address ref_token;
        address flax;
        OracleSet oracleSet;
        address issuer;
    }

    UniVARS public VARS;

    constructor(
        address flx
    )
        Ownable(msg.sender) //Governable(limboDAO)
    {
        VARS.factory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        VARS.flax = flx;
        _enabled = true;
    }

    function setEnabled(bool enabled) public onlyOwner {
        _enabled = enabled;
    }

    function configure(
        address ref_token,
        address flx,
        address oracle,
        address issuer
    ) public onlyOwner {
        VARS.ref_token = ref_token;
        VARS.flax = flx;

        LimboOracleLike limboOracle = LimboOracleLike(oracle);
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

        IERC20(flx_ref_token).approve(issuer, type(uint).max);
        VARS.issuer = issuer;
    }

    struct PriceTiltVARS {
        uint FlaxPerRef_token;
    }

    function getPriceTiltVARS(
        bool preview
    ) internal view returns (PriceTiltVARS memory tilt) {
        tilt.FlaxPerRef_token = VARS.oracleSet.oracle.consult(
            VARS.ref_token,
            VARS.flax,
            SPOT,
            preview
        );
    }

    uint public safeFlaxBalance;

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

    //If preview is true, a simulated oracle update is performed which isn't stored. This allows the UI to know what the values
    //would be if the oracle updates without spending gas.
    function refValueOfTilt(
        uint ref_amount,
        bool preview // if the oracle hasn't been updated for a while
    ) public view returns (uint flax_new_balance, uint lpTokens) {
        PriceTiltVARS memory priceTilt = getPriceTiltVARS(preview);
        uint flx_amount = (ref_amount * priceTilt.FlaxPerRef_token * 6) /
            (10 * SPOT);

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

        lpTokens = Math.min(
            (mint_vars.amount0 * totalSupply) / mint_vars.reserve0,
            (mint_vars.amount1 * totalSupply) / mint_vars.reserve1
        );
    }

    function lp_price_in_ref() public view returns (uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            VARS.factory.getPair(VARS.ref_token, VARS.flax)
        );
        uint ref_balance = IERC20(VARS.ref_token).balanceOf(address(pair));
        return ((2 ether) * ref_balance) / pair.totalSupply();
    }

    function issue(
        address inputToken,
        address recipient
    ) public payable nonReentrant {
        uint amount = msg.value;
        IWETH(VARS.ref_token).deposit{value: msg.value}();
        issue(inputToken, amount, recipient);
    }

    //same signature for DI
    function issue(address inputToken, uint amount, address recipient) public {
        //SECURITY VALIDATIONS
        if (!_enabled) {
            revert TitlerHasBeenDisabledByOwner();
        }
        if (inputToken != VARS.ref_token) {
            revert InputTokenMismatch(inputToken, VARS.ref_token);
        }

        //UPDATE ORACLE
        generateFLXQuote();
        PriceTiltVARS memory priceTilting = getPriceTiltVARS(false);
        //END ORACLE UPDATE

        //TILT PRICE IN FAVOUR OF FLAX
        //tilt by 60%
        uint flxToMint = (amount * priceTilting.FlaxPerRef_token * 6) /
            (10 * SPOT);

        ICoupon(VARS.flax).mint(
            flxToMint,
            address(VARS.oracleSet.flx_ref_token)
        );
        IERC20(VARS.ref_token).transferFrom(
            msg.sender,
            address(VARS.oracleSet.flx_ref_token),
            amount
        );

        IUniswapV2Pair(VARS.oracleSet.flx_ref_token).mint(address(this));
        uint mintedLP = VARS.oracleSet.flx_ref_token.balanceOf(address(this));
        //END PRICE TILTING

        //DEPOSIT TO BONFIRE

        Issuer(VARS.issuer).issue(
            address(VARS.oracleSet.flx_ref_token),
            mintedLP,
            recipient
        );
        //DEPOSIT TO BONFIRE
    }

    //function renamed from generateFLNQuote
    function generateFLXQuote() internal {
        OracleSet memory set = VARS.oracleSet;
        LimboOracleLike oracle = set.oracle;
        UniVARS memory localVARS = VARS;

        (uint32 blockTimeStamp, uint256 period) = oracle.getLastUpdate(
            localVARS.flax,
            localVARS.ref_token
        );
        if (block.timestamp - blockTimeStamp > period) {
            set.oracle.update(localVARS.ref_token, localVARS.flax);
        }
    }
}
