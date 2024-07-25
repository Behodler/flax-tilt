// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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