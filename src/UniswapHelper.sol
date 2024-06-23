// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import {IERC20} from "@oz_tilt/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@oz_tilt/contracts/utils/ReentrancyGuard.sol";
import "@behodler/flax/IIssuer.sol";
import {ICoupon} from "@behodler/flax/ICoupon.sol";
import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "./LimboOracleLike.sol";
import "./Errors.sol";
import "./IWeth.sol";
import "./IStreamAdapter.sol";

contract BlackHole {}

///@author Justin Goro
/**@notice In order to re-use audited code, the UniswapHelper is copied from Limbo
 * to function as the price tilting contract for Flax. Some changes that only apply to Limbo but not to Flax have to be removed
 * In order to not introduce bugs of omission, code that doesn't belong is commented out with an explanation given. An explanation is omitted for duplicates.
 * Very large comments from the original contract are ommitted as they can be sought in Limbo and don't need to be replicated.
 * FLN changed to FLX etc
 */
contract UniswapHelper is
    Ownable,
    ReentrancyGuard
    //Explanation: governance is simple ownable
    /**is Governable, AMMHelper*/
{
    //Explanation: no Limbo
    // address limbo;

    uint256 constant SPOT = 1e8;

    struct OracleSet {
        IUniswapV2Pair flx_weth;
        //Explanation: The price tilting for Flx is a simplified version of Flan's
        // IUniswapV2Pair fln_scx;
        // IUniswapV2Pair dai_scx;
        // IUniswapV2Pair scx__fln_scx;
        LimboOracleLike oracle;
    }

    struct UniVARS {
        uint256 minQuoteWaitDuration;
        IUniswapV2Factory factory;
        //Explanation: SCX is replaced with weth
        address weth; //behodler;
        //Explanation: Tilter does not target a price but simply increases it always
        //uint8 priceBoostOvershoot; //percentage (0-100) for which the price must be overcorrected when strengthened to account for other AMMs
        address blackHole;
        address flax; //flan;
        //Explanation: no Dai targeting.
        //address DAI;
        OracleSet oracleSet;
        IStreamAdapter stream;
    }

    UniVARS public VARS;

    uint256 constant EXA = 1e18;

    uint256 constant year = 31536000; // seconds in 365 day year

    constructor(
        address flx
    )
        Ownable(msg.sender) //Governable(limboDAO)
    {
        //Explanation: no limbo
        // limbo = _limbo;
        VARS.blackHole = address(new BlackHole());
        VARS.factory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        //Explanation: no Dai
        //VARS.DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        VARS.flax = flx;
    }

    //Question for community: should this give of Hawking radiation?
    function blackHole() public view returns (address) {
        return VARS.blackHole;
    }

    //Explanation: no Dai
    // ///@param dai the address of the Dai token
    // ///@dev Only for testing: On mainnet Dai has a fixed address. Obviously alter for deployment to other real chains
    // function setDAI(address dai) public {
    //     if (block.chainid == 1) {
    //         revert NotOnMainnet();
    //     }
    //     VARS.DAI = dai;
    // }

    // Fallback function to handle calls with data
    fallback() external payable ethReceiver {
        // If Ether is sent, redirect to mint function
        if (msg.value > 0) {
            tiltFlax(msg.sender, msg.value, 4);
            (msg.sender, msg.value);
        } else {
            // Revert if no Ether is sent and no valid function is called
            revert("Invalid call");
        }
    }

    receive() external payable {
        // Revert any plain Ether transfers
        revert("Use fallback to send Ether");
    }

    function configure(
        //Explanation:omitted
        // address _limbo,
        address weth, //behodler,
        address flx, //flan,
        //Explanation: omitted
        // uint8 priceBoostOvershoot,
        address oracle,
        address stream
    )
        public
        //Explanation: different governance
        onlyOwner
    /*onlySuccessfulProposal*/ {
        //Explanation: see above
        // limbo = _limbo;
        // VARS.behodler = behodler;
        // VARS.flan = flan;

        VARS.weth = weth;
        VARS.flax = flx;
        VARS.stream = IStreamAdapter(stream);
        //Explanation: see above
        // if (priceBoostOvershoot > 99) {
        //     revert PriceOvershootTooHigh(priceBoostOvershoot);
        // }
        // VARS.priceBoostOvershoot = priceBoostOvershoot;

        LimboOracleLike limboOracle = LimboOracleLike(oracle);
        VARS.factory = limboOracle.factory();

        address flx_weth = VARS.factory.getPair(flx, weth);
        // address fln_scx = VARS.factory.getPair(flan, behodler);
        // address dai_scx = VARS.factory.getPair(VARS.DAI, behodler);
        // address scx__fln_scx = VARS.factory.getPair(behodler, fln_scx);

        address zero = address(0);

        //Explanation: different pairs are used
        // if (fln_scx == zero || dai_scx == zero || scx__fln_scx == zero) {
        //     revert OracleLPsNotSet(fln_scx, dai_scx, scx__fln_scx);
        // }
        if (flx_weth == zero) {
            revert OracleLPsNotSet(flx_weth);
        }

        VARS.oracleSet = OracleSet({
            oracle: limboOracle,
            flx_weth: IUniswapV2Pair(flx_weth)
            // fln_scx: IUniswapV2Pair(fln_scx),
            // dai_scx: IUniswapV2Pair(dai_scx),
            // scx__fln_scx: IUniswapV2Pair(scx__fln_scx)
        });
    }

    struct PriceTiltVARS {
        uint FlaxPerWeth;
        //Explanation: price tilting is much simpler for FLX
        // uint256 FlanPerSCX;
        // uint256 SCXPerFLN_SCX;
        // uint256 totalSupplyOfFLN_SCX;
        // uint256 currentSCXInFLN_SCX;
        // uint256 currentFLNInFLN_SCX;
        // uint256 DAIPerSCX;
    }

    //flan per scx. (0)
    //scx value of fln/scx (1)
    //total supply of fln/scx. (2)
    //flan in flan/scx = ((1*2)/2 * (0))
    function getPriceTiltVARS()
        internal
        view
        returns (PriceTiltVARS memory tilt)
    {
        tilt.FlaxPerWeth = VARS.oracleSet.oracle.consult(
            VARS.weth,
            VARS.flax,
            SPOT
        );

        //Explanation: simple tilting
        // tilt.FlanPerSCX = VARS.oracleSet.oracle.consult(
        //     VARS.behodler,
        //     VARS.flan,
        //     SPOT
        // );
        // tilt.SCXPerFLN_SCX = VARS.oracleSet.oracle.consult(
        //     address(VARS.oracleSet.fln_scx),
        //     VARS.behodler,
        //     SPOT
        // );
        // tilt.totalSupplyOfFLN_SCX = VARS.oracleSet.fln_scx.totalSupply(); // although this can be manipulated, it appears on both sides of the equation(cancels out)
        // tilt.DAIPerSCX = VARS.oracleSet.oracle.consult(
        //     VARS.behodler,
        //     VARS.DAI,
        //     SPOT
        // );
        // tilt.currentSCXInFLN_SCX =
        //     (tilt.SCXPerFLN_SCX * tilt.totalSupplyOfFLN_SCX) /
        //     (SPOT * 2); //normalized to units of 1 ether
        // tilt.currentFLNInFLN_SCX =
        //     (tilt.currentSCXInFLN_SCX * tilt.FlanPerSCX) /
        //     SPOT;
    }

    modifier ethReceiver() {
        if (msg.value > 0) IWETH(VARS.weth).deposit{value: msg.value}();
        _;
    }

    uint[5] public termLength = [30, 40, 60, 120, 360];
    //implicit APY%:     [13,42,58,64, 99]
    uint[5] public roi = [1, 4, 8, 18, 99];

    //note: we can hardcode these return relationships because the contract can always be redeployed
    function tiltFlax(
        uint termChoice
    ) external payable ethReceiver nonReentrant {
        require(msg.value > 1000_000, "Eth required");
        tiltFlax(msg.sender, msg.value, termChoice);
    }

    //function signature changes: renamed from stabilizeFlan and made private
    //function works so long as Flax is never worth more than about 1000 Eth. 
    function tiltFlax(
        address minter,
        uint256 eth, //mintedSCX replaced with eth
        uint termChoice
    ) private returns (uint256 lpMinted) {
        require(termChoice < 5, "Invalid term duration");
        // if (msg.sender != limbo) {
        //     revert OnlyLimbo(msg.sender, limbo);
        // }
        generateFLXQuote();
        PriceTiltVARS memory priceTilting = getPriceTiltVARS();

        //Explanation: FLX does not burn in any way
        // (uint256 transferFee, uint256 burnFee, ) = BehodlerLike(VARS.behodler)
        //     .config();

        //Explanation: we're not interested in levels, just spot price
        // uint256 transferredSCX = (mintedSCX * (1000 - transferFee - burnFee)) /
        //     1000;
        // uint256 finalSCXBalanceOnLP = (transferredSCX) +
        //     priceTilting.currentSCXInFLN_SCX;
        // uint256 DesiredFinalFlanOnLP = (finalSCXBalanceOnLP *
        //     priceTilting.DAIPerSCX) / SPOT;

        //This is the true eth value of the Flx and what he sender is at the very least entitled to.
        uint entitledFlx = (priceTilting.FlaxPerWeth * eth) / SPOT;
        //we assume 100% growth in FLX which is split between LP and user.
        uint userPremium = (roi[termChoice] * entitledFlx) / 100;
        uint tiltPortion = entitledFlx - userPremium;
        if (IERC20(VARS.flax).balanceOf(address(this)) < entitledFlx * 2) {
            revert InsufficientFlaxForTilting(
                IERC20(VARS.flax).balanceOf(address(this)),
                entitledFlx * 2
            );
        }

        //Explanation: reference pair is now flx_weth
        // address pair = address(VARS.oracleSet.fln_scx);
        address pair = address(VARS.oracleSet.flx_weth);

        IERC20(VARS.flax).transfer(pair, tiltPortion);
        IWETH(VARS.weth).transfer(pair, eth);
        lpMinted = VARS.oracleSet.flx_weth.mint(VARS.blackHole);
        IERC20(VARS.flax).approve(
            address(VARS.stream),
            entitledFlx + userPremium
        );
        VARS.stream.lock(
            minter,
            userPremium + entitledFlx,
            termLength[termChoice]
        );
        //Explanation: price stability logic not necessary
        // if (priceTilting.currentFLNInFLN_SCX < DesiredFinalFlanOnLP) {
        //     uint256 flanToMint = ((DesiredFinalFlanOnLP -
        //         priceTilting.currentFLNInFLN_SCX) *
        //         (100 - VARS.priceBoostOvershoot)) / 100;
        //     flanToMint = flanToMint == 0
        //         ? DesiredFinalFlanOnLP - priceTilting.currentFLNInFLN_SCX
        //         : flanToMint;
        //     FlanLike(VARS.flan).mint(pair, flanToMint);

        //     IERC20(VARS.behodler).transfer(pair, transferredSCX);
        //     {
        //         lpMinted = VARS.oracleSet.fln_scx.mint(VARS.blackHole);
        //     }
        // } else {
        //     uint256 minFlan = priceTilting.currentFLNInFLN_SCX /
        //         priceTilting.totalSupplyOfFLN_SCX;

        //     FlanLike(VARS.flan).mint(pair, minFlan + 2);
        //     IERC20(VARS.behodler).transfer(pair, transferredSCX);
        //     lpMinted = VARS.oracleSet.fln_scx.mint(VARS.blackHole);
        // }
    }

    //function renamed from generateFLNQuote
    function generateFLXQuote() internal {
        OracleSet memory set = VARS.oracleSet;
        LimboOracleLike oracle = set.oracle;
        UniVARS memory localVARS = VARS;

        //Explanation: replaced with relevant vars
        // (uint32 blockTimeStamp, uint256 period) = oracle.getLastUpdate(
        //     localVARS.behodler,
        //     localVARS.flan
        // );
        // if (block.timestamp - blockTimeStamp > period) {
        //     set.oracle.update(localVARS.behodler, localVARS.flan);
        // }
        (uint32 blockTimeStamp, uint256 period) = oracle.getLastUpdate(
            localVARS.flax,
            localVARS.weth
        );
        if (block.timestamp - blockTimeStamp > period) {
            set.oracle.update(localVARS.weth, localVARS.flax);
        }

        //Explanation:no longer relevant
        // //update scx/DAI if stale
        // (blockTimeStamp, period) = oracle.getLastUpdate(
        //     localVARS.behodler,
        //     localVARS.DAI
        // );
        // if (block.timestamp - blockTimeStamp > period)
        //     set.oracle.update(localVARS.behodler, localVARS.DAI);

        // //update scx/fln_scx if stale
        // (blockTimeStamp, period) = oracle.getLastUpdate(
        //     localVARS.behodler,
        //     address(set.fln_scx)
        // );
        // if (block.timestamp - blockTimeStamp > period)
        //     set.oracle.update(localVARS.behodler, address(set.fln_scx));
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
}
