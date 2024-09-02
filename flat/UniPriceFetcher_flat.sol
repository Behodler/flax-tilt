// SPDX-License-Identifier: MIT
pragma solidity =0.8.20 ^0.8.20;

// lib/UniswapV2CoreFoundryFriendly/src/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// lib/UniswapV2CoreFoundryFriendly/src/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// lib/UniswapV2PeripheryFoundryFriendly/src/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external  returns (address);
    function WETH() external  returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// src/Errors.sol

error NotAllowanceIncreaser();
error InvalidPair(address, address);
error InvalidToken(address, address);
error ReservesEmpty(address, uint112, uint112);
error UpdateOracle(address, address, uint);
error AssetNotRegistered(address);
error WaitPeriodTooSmall(uint, uint);
error OracleLPsNotSet(address);
error InsufficinetFunds(uint accountBalance, uint amount);
error InvocationFailure(address);
error NotAContract(address);
error ApproveToNonZero(address, address, uint);
error OperationFailure();
error AllowanceExceeded(uint, uint);
error InsufficientFlaxForTilting(uint flaxBalance, uint requiredAmount);
error TitlerHasBeenDisabledByOwner ();
error InputTokenMismatch(address inputToken, address referenceToken);
error EthImpliesWeth(address inputToken, address wethAddress);
error Debug (uint value, string reason);
error RefTokenTaken(address refToken, address existingTilter);
error AdoptionRequiresOwnershipTransfer(address existingOwner);
error TilterNotMapped(address tilter);

error TokenTypeUnset(address token);
error TokenFalselyClaimsToBeWeth(address token, address weth);
error InvalidLP(address token);

// lib/UniswapV2PeripheryFoundryFriendly/src/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

// src/UniPriceFetcher.sol

abstract contract PyroTokenWrapper {
    /*
        struct Configuration {
        address liquidityReceiver;
        IERC20 baseToken;
        address loanOfficer;
        bool pullPendingFeeRevenue;
    }
    */
    function config()
        public
        view
        virtual
        returns (address, address, address, bool);

    function redeemRate() public view virtual returns (uint);
}

enum TokenType {
    Unset,
    Base,
    Eth,
    LP,
    Pyro
}

contract UniPriceFetcher is Ownable {
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
    address weth;
    address dai;
    uint constant ONE = 1 ether;

    constructor(address routerAddress, address daiAddress) Ownable(msg.sender) {
        router = IUniswapV2Router02(routerAddress);
        weth = router.WETH();
        factory = IUniswapV2Factory(router.factory());
        dai = daiAddress;
    }

    mapping(address => TokenType) public tokenTypeMap;

    function setTokenTypeMap(
        address[] calldata tokens,
        TokenType[] calldata types
    ) external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            require(uint(types[i]) < 5, "invalid type");
            tokenTypeMap[tokens[i]] = types[i];
            validateMap(tokens[i], types[i]);
        }
    }

    function validateMap(address token, TokenType tokenType) private {
        if (tokenType == TokenType.Unset) {
            revert TokenTypeUnset(token);
        } else if (tokenType == TokenType.Eth && token != weth) {
            revert TokenFalselyClaimsToBeWeth(token, weth);
        } else if (tokenType == TokenType.LP) {
            IUniswapV2Pair pair = IUniswapV2Pair(token);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (factory.getPair(token0, token1) != token) {
                revert InvalidLP(token);
            }
            TokenType token0Type = tokenTypeMap[token0];
            TokenType token1Type = tokenTypeMap[token0];
            validateMap(token0, token0Type);
            validateMap(token1, token1Type);
        } else if (tokenType == TokenType.Pyro) {
            (, address baseToken, , ) = PyroTokenWrapper(token).config();
            TokenType baseTokenType = tokenTypeMap[baseToken];
            validateMap(baseToken, baseTokenType);
        }
    }

    function daiPriceOfToken(address token) public view returns (uint) {
        TokenType map = tokenTypeMap[token];
        if (map == TokenType.Unset) {
            revert TokenTypeUnset(token);
        }

        if (map == TokenType.Pyro) {
            //get redeem rate
            uint redeemRate = PyroTokenWrapper(token).redeemRate();
            (, address baseToken, , ) = PyroTokenWrapper(token).config();
            return (redeemRate * daiPriceOfToken(baseToken)) / (1 ether);
        } else if (map == TokenType.LP) {
            IUniswapV2Pair pair = IUniswapV2Pair(token);
            uint totalSupply = pair.totalSupply();
            address token0_a = pair.token0();
            address token1_a = pair.token1();
            IERC20 token0 = IERC20(token0_a);
            IERC20 token1 = IERC20(token1_a);
            uint bal_0 = token0.balanceOf(token);
            uint bal_1 = token1.balanceOf(token);

            uint combinedDollarValue = (daiPriceOfToken(token0_a) * bal_0) +
                (daiPriceOfToken(token1_a) * bal_1);
            return combinedDollarValue / totalSupply;
        } else {
            return daiPriceOfBaseToken(token, map == TokenType.Eth);
        }
    }

    function daiPriceOfTokens(
        address[] memory tokens
    ) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            prices[i] = daiPriceOfToken(tokens[i]);
        }
    }

    function daiPriceOfBaseToken(
        address token,
        bool isEth
    ) public view returns (uint) {
        uint wethPerDai = wethPriceOfBaseToken(dai, false);
        //W/D - 1000/3000
        //W/T  - 1000/50000
        //=>(W/T)/(W/D) = (W/T*D/W) = (D/T); = (1000/50000 * 3000/1000)
        uint wethPriceOfToken = wethPriceOfBaseToken(token, isEth);

        return (wethPriceOfToken * (ONE)) / wethPerDai;
    }

    function wethPriceOfBaseToken(
        address token,
        bool isEth
    ) public view returns (uint) {
        if (isEth) return ONE;

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        address pair = factory.getPair(token, weth);
        require(pair != address(0), "token without Weth pairing");
        uint tokenReserve = IERC20(token).balanceOf(pair);
        uint wethReserve = IERC20(weth).balanceOf(pair);
        return (wethReserve * ONE) / tokenReserve;
    }
}

