// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@oz_tilt/contracts/access/Ownable.sol";
import "@oz_tilt/contracts/utils/ReentrancyGuard.sol";

//Explanation: Identical to original PyroToken ERC20 but renamed to avoid clashes with openzeppelin
import "./PyroERC20.sol";
///@author Justin Goro
/**@notice In order to re-use audited code, the PyroToken 3 code is copied over. Unlike prior PyroTokens, this one isn't connected to Behodler and so doesn't reference the
 * Liquidity Provider. The reasons for this are:
 * 1. We can set the redemption fee much higher to induce hold incentives
 * 2. It simplifies the code since we need no fancy LR governance, no fee exemption governance, pyroLoans or rebaseWrapper.
 * Note that while fee exemption governance is ommitted, the fee governance logic still remains. It's simply boolean
 * In order to not introduce bugs of omission, code that doesn't belong is commented out with an explanation given. An explanation is omitted for duplicates.
 * Very large comments from the original contract are ommitted as they can be sought in the original PyroToken3 repo and don't need to be replicated.
 */
contract PyroToken is PyroERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    //Explanation: No pyroloans
    //    event LoanOfficerAssigned(address indexed loanOfficer);
    // event LoanObligationSet(
    //     address borrower,
    //     uint256 baseTokenBorrowed,
    //     uint256 pyroTokenStaked,
    //     uint256 rate,
    //     uint256 slashBasisPoints
    // );

    struct Configuration {
        //Explanation: No LR
        // address liquidityReceiver;
        IERC20 baseToken;
        //Explanation: not hard coded to allow for experimentation
        uint redemptionFee;
        //Explanation: No PyroLoans
        // address loanOfficer;
        //Explanation: No LR
        // bool pullPendingFeeRevenue;
    }
    //Explanation: No PyroLoans
    // struct DebtObligation {
    //     uint256 base;
    //     uint256 pyro;
    //     uint256 redeemRate;
    //     uint256 lastUpdated;
    // }
    //Explanation: no rebase wrapper
    // address public rebaseWrapper;

    // uint256 public aggregateBaseCredit;
    Configuration public config;
    uint256 private constant ONE = 1 ether;

    //Explanation: bool replaces enum. True is SENDER_EXEMPT_AND_RECEIVER_EXEMPT. This allows the token to operate in fee hostile environments.
    mapping(address => bool) public feeExemptionStatus;

    //Explanation: no PyroLoans
    // mapping(address => DebtObligation) public debtObligations;

    /**@dev LiquidityReceiver subscribes the PyroToken to trade revenue from the Behodler AMM. It's a pull based feed.
     * Behodler sends fee to LiquidityReceiver. Corresponding PyroToken pulls the accumulated fees on mint, before calculating the minted value
     */
    constructor(
        address flax,
        string memory name_,
        string memory symbol_
    ) Ownable(msg.sender) PyroERC20(name_, symbol_) {
        config.baseToken = IERC20(flax);
        //config.liquidityReceiver = msg.sender;
        //config.pullPendingFeeRevenue = true;
    }

    function setRedemptionFee(uint fee) external onlyOwner {
        config.redemptionFee = fee % 1000;
    }

    //Explanation: initialization complexity removed
    // modifier initialized() {
    //     if (address(config.baseToken) == address(0)) {
    //         revert BaseTokenNotSet(address(this));
    //     }
    //     _;
    // }

    // modifier onlyReceiver() {
    //     _onlyReceiver();
    //     _;
    // }

    // function _onlyReceiver() internal view {
    //     if (msg.sender != config.liquidityReceiver) {
    //         revert OnlyReceiver(config.liquidityReceiver, msg.sender);
    //     }
    // }

    //Explanation: no LR means no fee revenue
    // function _updateReserve() internal {
    //     if (config.pullPendingFeeRevenue) {
    //         LiquidityReceiverLike(config.liquidityReceiver).drain(
    //             address(config.baseToken)
    //         );
    //     }
    // }
    // modifier updateReserve() {
    //     _updateReserve();
    //     _;
    // }

    // modifier onlyLoanOfficer() {
    //     if (msg.sender != config.loanOfficer) {
    //         revert OnlyLoanOfficer(config.loanOfficer, msg.sender);
    //     }
    //     _;
    // }

    //Explanation: no complex initialization code
    // function initialize(
    //     address baseToken,
    //     string memory name_,
    //     string memory symbol_,
    //     uint8 decimals,
    //     address bigConstantsAddress,
    //     address proxyHandler
    // ) external onlyReceiver {
    //     config.baseToken = IERC20(baseToken);
    //     _name = name_;
    //     _symbol = symbol_;
    //     _decimals = decimals;
    //     rebaseWrapper = BigConstantsLike(bigConstantsAddress)
    //         .deployRebaseWrapper(address(this));

    //     //disable all fees so that holders can toggle back and forth without penalty
    //     feeExemptionStatus[rebaseWrapper] = FeeExemption
    //         .REDEEM_EXEMPT_AND_SENDER_EXEMPT_AND_RECEIVER_EXEMPT;

    //     //disable all fees for the proxyHandler
    //     feeExemptionStatus[proxyHandler] = FeeExemption
    //         .SENDER_EXEMPT_AND_RECEIVER_EXEMPT;
    // }

    //Explanation: no PyroLoans
    // function setLoanOfficer(address loanOfficer) external onlyReceiver {
    //     config.loanOfficer = loanOfficer;
    // }

    //Explanation: no LR
    // function togglePullPendingFeeRevenue(
    //     bool pullPendingFeeRevenue
    // ) external onlyReceiver {
    //     config.pullPendingFeeRevenue = pullPendingFeeRevenue;
    // }

    //Explanation: simplified. LR replaced with Owner
    function setFeeExemptionStatusFor(
        address target,
        // FeeExemption status
        bool exempt
    ) external onlyOwner /*onlyReceiver*/ {
        feeExemptionStatus[target] = exempt;
    }

    //Explanation: Ownable's transfer ownership handles this case
    // function transferToNewLiquidityReceiver(
    //     address liquidityReceiver
    // ) external onlyReceiver {
    //     if (liquidityReceiver == address(0)) {
    //         revert AddressNonZero();
    //     }
    //     config.liquidityReceiver = liquidityReceiver;
    // }

    //Explanation: this is simplified since LR is gone. Logic is unchanged for security reasons.
    function mint(
        address recipient,
        uint256 amount /*updateReserve  initialized*/
    ) public returns (uint256 minted) {
        //redeemRate() is altered by a change in the reserves and so must be captured before hand.
        uint256 _redeemRate = redeemRate();
        IERC20 baseToken = config.baseToken;

        //fee on transfer token safe
        uint256 balanceBefore = baseToken.balanceOf(address(this));
        baseToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 changeInBalance = baseToken.balanceOf(address(this)) -
            balanceBefore;

        //r = R/T where r is the redeem rate, R is the base token reserve and T is the PyroToken supply.
        // This says that 1 unit of this PyroToken is worth r units of base token.
        //=> 1 pyroToken = 1/r base tokens
        //=> pyroTokens minted = base_token_amount * 1/r
        minted = (changeInBalance * ONE) / _redeemRate;
        _mint(recipient, minted);
    }

    /**@notice redeems base tokens for a given pyrotoken amount at the current redeem rate
    @param recipient recipient of the redeemed base tokens
    @param amount of pyroTokens to transfer from recipient
     */
    function redeem(
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return _redeem(recipient, msg.sender, amount);
    }

    function redeemRate() public view returns (uint256) {
        uint256 ts = _totalSupply;
        if (ts == 0) return ONE;

        //Explanation: no pyroloans removes credit variable
        return
            ((
                config.baseToken.balanceOf(
                    address(this)
                ) /*+ aggregateBaseCredit*/
            ) * ONE) / (ts);
    }

    /**@notice Standard ERC20 transfer
     *@dev PyroToken fee logic implemented in _transfer
     *@param recipient the recipient of the token
     *@param amount the amount of tokens to transfer
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**@notice Standard ERC20 transferFrom
     *@dev PyroToken fee logic implemented in _transfer
     *@param sender the sender of the token
     *@param recipient the recipient of the token
     *@param amount the amount of tokens to transfer
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];

        if (
            currentAllowance != type(uint256).max //&& msg.sender != rebaseWrapper
        ) {
            if (currentAllowance < amount) {
                revert AllowanceExceeded(currentAllowance, amount);
            }
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        return true;
    }

    //Explanation: no PyroLoans
    // function setObligationFor(
    //     address borrower,
    //     uint256 baseTokenBorrowed,
    //     uint256 pyroTokenStaked,
    //     uint256 slashBasisPoints
    // ) external onlyLoanOfficer nonReentrant returns (bool success) {
    //     if (slashBasisPoints > 10000) {
    //         revert SlashPercentageTooHigh(slashBasisPoints);
    //     }
    //     DebtObligation memory currentDebt = debtObligations[borrower];
    //     uint256 rate = redeemRate();

    //     uint256 minPyroStake = (baseTokenBorrowed * ONE) / rate;
    //     if (pyroTokenStaked < minPyroStake) {
    //         revert UnsustainablePyroLoan(pyroTokenStaked, minPyroStake);
    //     }

    //     debtObligations[borrower] = DebtObligation(
    //         baseTokenBorrowed,
    //         pyroTokenStaked,
    //         rate,
    //         block.timestamp
    //     );

    //     //netStake > 0 is deposit and < 0 is withdraw
    //     int256 netStake = int256(pyroTokenStaked) - int256(currentDebt.pyro);
    //     uint256 stake;
    //     uint256 borrowerPyroBalance = _balances[borrower];
    //     if (netStake > 0) {
    //         stake = uint256(netStake);

    //         if (borrowerPyroBalance < stake) {
    //             revert StakeFailedInsufficientBalance(
    //                 borrowerPyroBalance,
    //                 stake
    //             );
    //         }
    //         unchecked {
    //             //A DAO approved LoanOfficer does not require individual holder approval.
    //             //Staking is not subject to transfer fees.
    //             _balances[borrower] -= stake;
    //         }
    //         //Staked Pyro stored on own contract. Not in unchecked in case Pyro wraps a hyperinflationary token.
    //         _balances[address(this)] += stake;
    //     } else if (netStake < 0) {
    //         stake = uint256(-netStake);
    //         uint256 netReceipt = ((10000 - slashBasisPoints) * stake) / 10000;

    //         if (slashBasisPoints > 0) {
    //             //burn pyrotoken
    //             _totalSupply -= stake - netReceipt;
    //         }
    //         _balances[borrower] += netReceipt;
    //         _balances[address(this)] -= stake;
    //     }

    //     //netBorrowing > 0, staker is borrowing, <0, staker is paying down debt.
    //     int256 netBorrowing = int256(baseTokenBorrowed) -
    //         int256(currentDebt.base);
    //     if (netBorrowing > 0) {
    //         aggregateBaseCredit += uint256(netBorrowing);
    //         config.baseToken.safeTransfer(borrower, uint256(netBorrowing));
    //     } else if (netBorrowing < 0) {
    //         uint256 absoluteBorrowing = uint256(-netBorrowing);
    //         aggregateBaseCredit -= absoluteBorrowing;
    //         config.baseToken.safeTransferFrom(
    //             borrower,
    //             address(this),
    //             absoluteBorrowing
    //         );
    //     }
    //     emit LoanObligationSet(
    //         borrower,
    //         baseTokenBorrowed,
    //         pyroTokenStaked,
    //         rate,
    //         slashBasisPoints
    //     );
    //     success = true;
    // }

    function calculateTransferFee(
        uint256 amount,
        address sender,
        address receiver
    ) public view returns (uint256) {
        //Explanation: simplified. Note setting a sending or receiver to true sets both to exempt
        // uint256 senderStatus = uint256(feeExemptionStatus[sender]);
        // uint256 receiverStatus = uint256(feeExemptionStatus[receiver]);
        bool senderStatus = feeExemptionStatus[sender];
        bool receiverStatus = feeExemptionStatus[receiver];
        if (senderStatus || receiverStatus) {
            return 0;
        }
        return amount / 1000;
    }

    /**
     *@notice calculates the exemption adjusted redemption fee, depending on redeemer exemptions.
     *@param amount transfer amount
     *@param redeemer of pyroToken for underlying base token
     */
    function calculateRedemptionFee(
        uint256 amount,
        address redeemer
    ) public view returns (uint256) {
        //Explanation simplified
        // uint256 status = uint256(feeExemptionStatus[redeemer]);
        bool status = feeExemptionStatus[redeemer];
        if (status) return 0;
        //Explanation: soft coded to allow for experimentation
        // return (amount << 1) / 100;
        return (amount * config.redemptionFee) / 1000;
    }

    function _redeem(
        address recipient,
        address owner,
        uint256 amount
    ) internal 
    //Explanation: No LR
    //updateReserve 
    returns (uint256) {
        uint256 _redeemRate = redeemRate();
        _balances[owner] -= amount;
        uint256 fee = calculateRedemptionFee(amount, owner);

        uint256 net = amount - fee;
        //r = R/T where r is the redeem rate, R is the base token reserve and T is the PyroToken supply.
        // This says that 1 unit of this PyroToken is worth r units of base token.
        //
        //=> base_tokens_redeemed = r * (pyrotoken_amount - exit_fee)
        uint256 baseTokens = (_redeemRate * net) / ONE;

        _totalSupply -= amount;

        //pyro burn event
        emit Transfer(owner, address(0), amount);

        config.baseToken.safeTransfer(recipient, baseTokens);
        return baseTokens;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (recipient == address(0)) {
            burn(amount);
            return;
        }
        uint256 senderBalance = _balances[sender];
        uint256 fee = calculateTransferFee(amount, sender, recipient);

        _totalSupply -= fee;

        uint256 netReceived = amount - fee;
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += netReceived;

        emit Transfer(sender, recipient, amount);
    }
}
