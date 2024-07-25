// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@uniswap/core/interfaces/IUniswapV2Factory.sol";
/**
 *@title LimboOracleLike
 * @author Justin Goro
 * @notice This is a copy-paste of the LimboOracle facade.
  */
abstract contract LimboOracleLike {
  function factory() public virtual returns (IUniswapV2Factory);

  function RegisterPair(address pairAddress, uint256 period) public virtual;

  function update(address token0, address token1) public virtual;

  function update(address pair) public virtual;

  function consult(
    address pricedToken,
    address referenceToken,
    uint256 amountIn,
    bool preview
  ) external view virtual returns (uint256 amountOut);

  function getLastUpdate (address token1, address token2) public virtual view returns (uint32,uint);
}
