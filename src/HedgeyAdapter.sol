// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@oz_tilt/contracts/token/ERC20/IERC20.sol";
import {TokenLockupPlans} from "@hedgey/lockup/TokenLockupPlans.sol";
import {IStreamAdapter} from "./IStreamAdapter.sol";

contract HedgeyTokenLocker is IStreamAdapter {
    IERC20 _flax;
    TokenLockupPlans _hedgey;

    constructor(address flax, address hedgey) {
        _flax = IERC20(flax);
        _hedgey = TokenLockupPlans(hedgey);
    }

    function lock(
        address recipient,
        uint amount,
        uint durationInDays
    ) external {
        //No need for helper libs because this assumes flax
        _flax.transferFrom(msg.sender, address(this), quantity);
        uint durationInSeconds = durationInDays * 24 * 60 * 60;
        //linear streaming per second
        uint rate = amount/durationInSeconds;

        _hedgey.createPlan(
            recipient,
            address(_flax),
            amount,
            now + 60,
            0,
            rate,
            1
        );
    }
}
