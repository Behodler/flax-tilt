// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
interface IStreamAdapter {
    function lock(address recipient, uint amount, uint durationInDays) external returns (uint id);
}