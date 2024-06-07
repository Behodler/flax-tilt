// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@oz_tilt/contracts/access/Ownable.sol";
import "@oz_tilt/contracts/utils/ReentrancyGuard.sol";
import "@superfluid/contracts/superfluid/SuperToken.sol";
import "@superfluid/contracts/interfaces/superfluid/ISuperToken.sol";
import "@superfluid/contracts/interfaces/superfluid/ISuperfluid.sol";
import "@oz_tilt/contracts/token/ERC20/utils/SafeERC20.sol";

// Explanation: Identical to original PyroFlax ERC20 but renamed to avoid clashes with openzeppelin
import "./PyroERC20.sol";

/// @author Justin Goro
/** @notice In order to re-use audited code, the PyroFlax 3 code is copied over. Unlike prior PyroFlaxs, this one isn't connected to Behodler and so doesn't reference the
 * Liquidity Provider. The reasons for this are:
 * 1. We can set the redemption fee much higher to induce hold incentives
 * 2. It simplifies the code since we need no fancy LR governance, no fee exemption governance, pyroLoans or rebaseWrapper.
 * Note that while fee exemption governance is omitted, the fee governance logic still remains. It's simply boolean
 * In order to not introduce bugs of omission, code that doesn't belong is commented out with an explanation given. An explanation is omitted for duplicates.
 * Very large comments from the original contract are omitted as they can be sought in the original PyroFlax3 repo and don't need to be replicated.
 */
contract PyroFlax is PyroERC20, SuperTokenBase, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Configuration {
        IERC20 baseToken;
        uint redemptionFee;
    }

    Configuration public config;
    uint256 private constant ONE = 1 ether;
    mapping(address => bool) public feeExemptionStatus;

    constructor(
        address flax,
        string memory name_,
        string memory symbol_,
        ISuperfluid host
    ) Ownable(msg.sender) PyroERC20(name_, symbol_) SuperTokenBase(host) {
        config.baseToken = IERC20(flax);
        initialize(host, name_, symbol_, 18, address(this));
    }

    function setRedemptionFee(uint fee) external onlyOwner {
        config.redemptionFee = fee % 1000;
    }

    function setFeeExemptionStatusFor(address target, bool exempt) external onlyOwner {
        feeExemptionStatus[target] = exempt;
    }

    function mint(address recipient, uint256 amount) public returns (uint256 minted) {
        uint256 _redeemRate = redeemRate();
        IERC20 baseToken = config.baseToken;

        uint256 balanceBefore = baseToken.balanceOf(address(this));
        baseToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 changeInBalance = baseToken.balanceOf(address(this)) - balanceBefore;

        minted = (changeInBalance * ONE) / _redeemRate;
        _mint(recipient, minted);
    }

    function redeem(address recipient, uint256 amount) external returns (uint256) {
        return _redeem(recipient, msg.sender, amount);
    }

    function redeemRate() public view returns (uint256) {
        uint256 ts = _totalSupply;
        if (ts == 0) return ONE;

        return (config.baseToken.balanceOf(address(this)) * ONE) / ts;
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert("Allowance exceeded");
            }
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        return true;
    }

    function calculateTransferFee(uint256 amount, address sender, address receiver) public view returns (uint256) {
        bool senderStatus = feeExemptionStatus[sender];
        bool receiverStatus = feeExemptionStatus[receiver];
        if (senderStatus || receiverStatus) {
            return 0;
        }
        return amount / 1000;
    }

    function calculateRedemptionFee(uint256 amount, address redeemer) public view returns (uint256) {
        bool status = feeExemptionStatus[redeemer];
        if (status) return 0;
        return (amount * config.redemptionFee) / 1000;
    }

    function _redeem(address recipient, address owner, uint256 amount) internal returns (uint256) {
        uint256 _redeemRate = redeemRate();
        _balances[owner] -= amount;
        uint256 fee = calculateRedemptionFee(amount, owner);

        uint256 net = amount - fee;
        uint256 baseTokens = (_redeemRate * net) / ONE;

        _totalSupply -= amount;
        emit Transfer(owner, address(0), amount);

        config.baseToken.safeTransfer(recipient, baseTokens);
        return baseTokens;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
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
