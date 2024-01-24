
![Algem](https://github.com/azhlbn/LendingAdapter/blob/main/logo.png)

## Liquid Staking v1.5 adapted to Dapps Staking v3

The LiquidCrowdloan contract allows users to use their ASTR tokens to receive allocations in the form of ALGM tokens, while during the lock period of their ASTR tokens, they receive aASTR tokens. 
During the Crowdloan period, the contract accepts users' ASTR tokens and uses them in Astar's DappsStaking. For each user, aASTR tokens equivalent to the size of their stake are minted. At the end of the Crowdloan period, vesting is created, and for 6 months, each user receives rewards in the form of ALGM tokens. When the distribution ends, there is an opportunity to withdraw ASTR tokens in exchange for the previously received aASTR.

### The functionality

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