# Price impact attack vector

For Uniswap V2 TWAP oracles, reliable data can only be given on a moving average of price. However this is an average price that does not take into account price impact. 
For projects that use the oracles for purchasing or minting, this creates an arbitrage risk where the cost of buying on the open market is always compared to the oracle price.

For instance, if we can mint a token using the oracle price or buy the token on Uniswap, then the bigger the purchase, the more the open market price will fall below the oracle price.

This opens up attack vectors of all sorts. The most common solution profferred is to have lots of liquidity because time weighting makes liquid pools exponentially difficult to attack. But this can leave the pool vulnerable leading up to that.

# Flan vs Flax

Flan isn't purchased directly and instead the new Flan is created as a by product of a liquidity event. So average prices make sense. In addition, Flan has a number of sophisticated oracle tricks for inferring things safely (audited). However, this requires creating many exotic pairs such as fln_scx/fln. With a staking dapp such as Limbo, we can easily capitalize these pairs but we don't have this option with Flx. In addition, Flx tilting isn't a by product of a liquidity operation (migration) but is a kind of purhcase. 

If we could factor in a reliable price impact when tilting Flx then attackers would not be able to create any discrepancies. The only way to do this is to have oracles on the reserve amounts. Uniswap does not provide this.

Creating sophisticated code to track moving reserve oracles would require an audit. We're still operating under a keep-it-simple-to-avoid-audit principle.

## Two solutions that don't require audits.

1. **Locking** the rewards eliminates many flash loan attacks but this does not eliminate the risk of overminting relative to the market.
2. **Guarded Flx transfers**. Tilter can't mint. It has to be preloaded with Flx. By not allowing anyone except contract owner to fill up Tilter with FLX, we play things safe in the early days and if everything goes well, ease in.

