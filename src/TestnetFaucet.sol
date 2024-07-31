// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ICoupon} from "@behodler/flax/ICoupon.sol";
import "@oz_flax/contracts/access/Ownable.sol";

contract TestnetFaucet is Ownable {
    constructor() Ownable(msg.sender) {}

    mapping(address => bool) approvedTokens;

    function setApproved(address token, bool approved) public onlyOwner {
        approvedTokens[token] = approved;
    }

    function mint(address[] calldata tokens) public {
        for (uint i = 0; i < tokens.length; i++) {
            if (approvedTokens[tokens[i]]) {
                ICoupon(tokens[i]).mint(10 ether, msg.sender);
            }
        }
    }
}
