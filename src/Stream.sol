// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@oz_tilt/contracts/token/ERC20/IERC20.sol";

interface IStreamAdapter {
    function lock(address recipient, uint quantity, uint durationInDays) external;
}

contract HedgeyTokenLocker is IStreamAdapter {
      
      IERC20 _flax;
      constructor (address flax) {
        _flax = IERC20(flax);
      }

      function lock(address recipient, uint quantity, uint durationInDays) external  {
         //No need for helper libs because this assumes flax
         _flax.transferFrom(msg.sender,address(this),quantity);
        
      }
}