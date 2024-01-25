
![Algem](https://github.com/azhlbn/LendingAdapter/blob/main/logo.png)

# Liquid Staking v1.5

This version is adapted for [Dapps Staking V3](https://github.com/AstarNetwork/Astar/tree/master/precompiles/dapp-staking-v3).

Algem - LiquidStaking serves as an intermediary between the user and [Astar's Dapp Staking](https://portal.astar.network/astar/dapp-staking/discover). The user can choose the application in which they want to stake their ASTR, and after staking, they receive an equivalent amount of nASTR, which can be used in other DeFi instruments later on.

## Architecture

- LiquidStaking
  - LiquidStaking
  - LiquidStakingManager
  - LiquidStakingMain
  - LiquidStakingAdmin

- NASTR

- NDistributor

- Adapters
  - SiriusAdapter
  - KaglaAdapter
  - ArthswapAdapter
  - Sio2Adapter

- NFTDistributor

Contracts are implemented using the Diamond pattern, and the main contract that handles calls is `LiquidStaking`. Subsequently, the calls are redirected to `LiquidStakingManager`, which, based on the selector of the invoked function, determines the required contract address.

`NASTR` is the native token of the Algem protocol and is minted to users when they stake an amount equivalent to their stake.

`NDistributor` is designed to track the nASTR balances of users in each specific "utility". For example, if a user stakes 50 ASTR in the "Sirius" dapp, the user's balance in the "Sirius" utility will also increase by 50 ASTR. `NDistributor` is called every time there is movement of the NASTR token.
  
`Adapters` are contracts that reflect the functionality of partner dapps and should be utilized to ensure that the amount of nASTR transferred by users to partner applications for additional benefits is also considered when calculating rewards from Dapps Staking.

If a user owns a native Algem NFT, they are eligible for a discount when paying fees for Dapps Staking rewards. `NFTDistributor` is used to account for tokens ownership.

## The main functionality

- stake
- unstake
- claim/claimAll
- withdraw

## Dapps Staking V3 update struture

```src/
----interfaces/
    | ILiquidStakingMain.sol
    | ILiquidStakingAdmin.sol
    | ...
...
LiquidStakingMain.sol
LiquidStakingAdmin.sol
```
