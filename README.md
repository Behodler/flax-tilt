# Flax-tilt

## Introduction
Flax tilt is blockchain level middleware for the Bonfire dapp aka [Issuer.sol](https://github.com/Behodler/Flax/blob/linear-growth/src/Issuer.sol). It allows for Issuer to issue Flax in return for unrelated token deposits such as Eth or Uni while boosting Flax liquidity under the hood.

## Recap: What is Issuer?
Issuer is a contract which accepts deposits in the form of a whitelisted set of tokens. Instead of staking, the deposits are permanently locked. In return, Flax (ERC20) is immediately minted and streamed to the depositing user via the streaming dapp [Hedgey](https://hedgey.finance).

### Price setting
Since Flax is streamed over an extended period, a user would need to be compensated with a premium. Instead of complex oracle code, the price for each input token rises every second. At some point a user would be tempted to take the current price. On deposit, the price drops back to zero and begins climging again.

### Flax liquidity.
Most staking dapps offer liquidity pools which include the payment token in order to induce user to increase liquidity, making the staking sustainable. This is possible for Bonfire but there is a more user friendly option, not avaiable to stakers

# Price Tilting
Suppose we wish to increase FLX/WETH liquidity. We could accept deposits of the FLX/WETH Uniswap liquidity pool. But since we can mint FLX, we need only accept WETH. On deposit of WETH, FLX is minted and combined with the WETH to mint LP tokens. These are then deposited in Issuer and the FLX is minted and streamed to the user.

Suppose 1 Eth is deposited. If we mint 1 Eth worth of FLX, then the price will remain stable. If we mint less than 1 Eth worth of FLX and mint LP tokens, the price actually increases. This is known as price tilting.

## Contracts
Each input token that has a corresponding Flx LP pair gets its own Tilter contract. These act as middeware which deposit to Issuer so that the entire operation can happen in the span of one transaction. The TilterFactory contract maintains a mapping of token to Titlers, similar to UniswapV2's factory.