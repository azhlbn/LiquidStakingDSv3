
![Algem](https://github.com/azhlbn/LendingAdapter/blob/main/logo.png)

# Liquid Staking v1.5

This version is adapted for [Dapps Staking V3](https://github.com/AstarNetwork/Astar/tree/master/precompiles/dapp-staking-v3).

Algem - iquidStaking serves as an intermediary between the user and [Astar's Dapp Staking](https://portal.astar.network/astar/dapp-staking/discover). The user can choose the application in which they want to stake their ASTR, and after staking, they receive an equivalent amount of nASTR, which can be used in other DeFi instruments later on.

## The functionality

- `stake` 
  Deposit ASTR tokens and receive aASTR in return

- `unstake` 
  Transfer of aASTR to start the unbonding period

- `withdraw`
   Withdrawal of previously staked ASTR after the unbonding period has passed

- `claimReawards`
  Receiving distributed ALGM tokens

- `becomeReferrer` 
  Become a referrer and receive a referral link
  

## ALGMVesting

### The functionality

### Vesting

- Create vesting for a beneficiary
- Revoke created vesting
  - If this was implied during creating
  - Tokens accumulated to the moment of revoking will be sent to beneficiary
  - Remaining tokens will be available for withdrawal by manager
- Claim of tokens accumulated in vesting
- Withdraw tokens from revoked vestings

### Mass Vesting

- Create vesting for set of beneficiaries
- Revoke created vesting
  - If this was implied during creating
  - Tokens accumulated to the moment of revoking will NOT be sent to beneficiaries
- Claim of tokens accumulated in mass vesting
- Withdraw tokens from revoked mass vestings

### Airdrop

- Top up AirdropPool
  - Amount being added to pool should be equal to the sum of all airdrop receivers amounts
  - E.g: 10K users eligible for 10K ALGM each, AP should contain `10K*10K` tokens
  - Topping up airdrop pool automatically unlocks third of that amount being added
- Withdraw unclaimemd tokens from AirdropPool
- 6 month airdrop period should be over
- Unlock portion of airdrop
- Claim airdropped tokens

### Management

- Change admin
  - Pass `ADMIN` role to another address
  - Used for manager controlling operations
- Add manager
- Delete manager
- Withdraw stuck ERC20 tokens