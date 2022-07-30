Description
Total supply of liquidity tokens is zero at that time an attacker executes the following steps
The Attacker call [initiate Deposit](https://github.com/lyra-finance/lyra-protocol/blob/avalon/contracts/LiquidityPool.sol#L227) function, [initiate Deposit](https://github.com/lyra-finance/lyra-protocol/blob/avalon/contracts/LiquidityPool.sol#L227) is just an investment in an underlying token(sUSD) and issue shares by minting Liquidity token(LYEthPt), which values is same as underlying.
After that attacker call [initiateWithdraw](https://github.com/lyra-finance/lyra-protocol/blob/avalon/contracts/LiquidityPool.sol#L267).
where amount : (liquidity token- 1 Wei),
now the balance of liquidity token in the liquidity Pool is 1 Wei.
Now Attacker transfer underlying asset directly to the [liquidity pool](https://optimistic.etherscan.io/address/0x5Db73886c4730dBF3C562ebf8044E19E8C93843e) contract, Attacker can transfer this because of [baseAsset](https://github.com/lyra-finance/lyra-protocol/blob/avalon/contracts/LiquidityPool.sol#L847) and [quoteAsset](https://github.com/lyra-finance/lyra-protocol/blob/avalon/contracts/LiquidityPool.sol#L8480) will calculate using addree(this).
where amount: X (any big number)
now the price of the Liquidity token in the liquidity Pool is X + some amount.
attacker didn't have a problem transferring a big number, because an attacker can claim that amount just using 1 Wei.
Attack
First Deposit funds will steal using Frontrun by Attacker.
User deposits Y amount then the attacker see the transaction and do the same transaction with the above steps but where (X>=Y).
So user the user gets Zero liquidity token and loss the deposited amount too.
an attacker can claim all prices of liquidity tokens using their 1 Wei liquidity token which worth is (X*Y)+ some amount.
FundsRisk
Right now No funds at risk, but whenever you deploy new liquidity tokens (like lyraV1 have a pool for BTC, ETH, and many more) at that time first deposit funds are at risk also you have an automated strategy so every new strategy will be a risk.
Also protocol that is building on top of the Lyra(ex: polynomial) also has the same bug when they deposit funds(which is a huge amount).
POC:
attaching an attacker contract for POC. This is for liquidity tokens when totalSupply of liquidity tokens was zero.
To run this, fork mainnet at blockNumber: 12969633 and deploy the below contract with 50 ether as value
Call attack and userDeposit functions.
They both needs to be succeeded