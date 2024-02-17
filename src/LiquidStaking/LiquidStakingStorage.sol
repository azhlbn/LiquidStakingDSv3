// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/DappsStaking.sol";
import "../NDistributor.sol"; /* unused and will removed with next proxy update */
import "../interfaces/IPartnerHandler.sol"; /* 1 -> 1.5 will removed with next proxy update */
import "../interfaces/INFTDistributor.sol";
import "../interfaces/IAdaptersDistributor.sol";
import "../libraries/Errors.sol";

abstract contract LiquidStakingStorage {
    DappsStaking public constant DAPPS_STAKING =
        DappsStaking(0x0000000000000000000000000000000000005001);
    bytes32 public constant MANAGER = keccak256("MANAGER");

    /// @notice settings for distributor
    string public utilName;
    string public DNTname;

    /// @notice core values
    uint256 public totalBalance;
    uint256 public withdrawBlock;

    /// @notice pool values
    uint256 public unstakingPool;
    uint256 public rewardPool;

    /// @notice distributor data
    NDistributor public distr;

    /* unused and will removed with next proxy update */ struct Stake {
        /* unused and will removed with next proxy update */ uint256 totalBalance;
        /* unused and will removed with next proxy update */ uint256 eraStarted;
        /* unused and will removed with next proxy update */
    }
    /* unused and will removed with next proxy update */ mapping(address => Stake)
        public stakes;

    /// @notice user requested withdrawals
    struct Withdrawal {
        uint256 val;
        uint256 eraReq;
        uint256 lag;
    }
    mapping(address => Withdrawal[]) public withdrawals;

    /* unused and will removed with next proxy update */ // @notice useful values per era
    /* unused and will removed with next proxy update */ struct eraData {
        /* unused and will removed with next proxy update */ bool done;
        /* unused and will removed with next proxy update */ uint256 val;
        /* unused and will removed with next proxy update */
    }
    /* unused and will removed with next proxy update */ mapping(uint256 => eraData)
        public eraUnstaked;
    /* unused and will removed with next proxy update */ mapping(uint256 => eraData)
        public eraStakerReward; // total staker rewards per era
    /* unused and will removed with next proxy update */ mapping(uint256 => eraData)
        public eraRevenue; // total revenue per era

    uint256 public unbondedPool;

    uint256 public lastUpdated; // last era updated everything

    // Reward handlers
    /* unused and will removed with next proxy update */ address[]
        public stakers;
    /* unused and will removed with next proxy update */ address
        public dntToken;
    mapping(address => bool) public isStaker;

    /* unused and will removed with next proxy update */ uint256
        public lastStaked;
    uint256 public lastUnstaked;

    /// @notice handlers for work with LP tokens
    /* unused and will removed with next proxy update */ mapping(address => bool)
        public isLpToken;
    /* unused and will removed with next proxy update */ address[]
        public lpTokens;

    /* unused and will removed with next proxy update */ mapping(uint256 => uint256)
        public eraRewards;

    uint256 public totalRevenue;

    /* unused and will removed with next proxy update */ mapping(address => mapping(uint256 => uint256))
        public buffer;
    mapping(address => mapping(uint256 => uint256[]))
        public usersShotsPerEra; /* 1 -> 1.5 will removed with next proxy update */
    mapping(address => uint256) public totalUserRewards;
    /* unused and will removed with next proxy update */ mapping(address => address)
        public lpHandlers;

    uint256
        public eraShotsLimit; /* 1 -> 1.5 will removed with next proxy update */
    /* unused and will removed with next proxy update */ uint256
        public lastClaimed;
    uint256 public minStakeAmount;
    /* remove after migration */ uint256 public sum2unstake;
    /* unused and will removed with next proxy update */ bool public isUnstakes;
    /* unused and will removed with next proxy update */ uint256
        public claimingTxLimit; // = 5;

    uint8 public constant REVENUE_FEE = 9; // 9% fee on MANAGEMENT_FEE
    uint8 public constant UNSTAKING_FEE = 1; // 1% fee on MANAGEMENT_FEE
    uint8 public constant MANAGEMENT_FEE = 10; // 10% fee on staking rewards

    // to partners will be added handlers and adapters. All handlers will be removed in future
    /* unused and will removed with next proxy update */ mapping(address => bool)
        public isPartner;
    /* unused and will removed with next proxy update */ mapping(address => uint256)
        public partnerIdx;
    address[]
        public partners; /* 1 -> 1.5 will removed with next proxy update */
    /* unused and will removed with next proxy update */ uint256
        public partnersLimit; // = 15;

    struct Dapp {
        address dappAddress;
        uint256 stakedBalance;
        uint256 sum2unstake;
        mapping(address => Staker) stakers;
    }

    struct Staker {
        // era => era balance
        mapping(uint256 => uint256) eraBalance;
        // era => is zero balance
        mapping(uint256 => bool) isZeroBalance;
        uint256 rewards;
        uint256 lastClaimedEra;
    }
    uint256 public lastEraTotalBalance;
    uint256[2] public eraBuffer;

    string[] public dappsList;
    // util name => dapp
    mapping(string => Dapp) public dapps;
    mapping(string => bool) public haveUtility;
    mapping(string => bool) public isActive;
    mapping(string => uint256) public deactivationEra;
    mapping(uint256 => uint256) public accumulatedRewardsPerShare;

    uint256 public constant REWARDS_PRECISION = 1e12;

    INFTDistributor public nftDistr;
    IAdaptersDistributor public adaptersDistr;

    address public liquidStakingManager;

    bool public paused;
    bool public partiallyPaused;

    // ds v3 update
    struct Period {
        bool initialized;
        uint256 voteStake;
        uint256 buidAndEarnStake;

        /// @dev 1st key is the period number, 2nd key is the user address
        mapping(uint256 => mapping(address => int256)) b2eStakes;
    }

    mapping(uint256 => Period) public periods;

    uint256 public maxDappsAmountPerCall;
    uint256 public bonusRewardsPool;
    
    mapping(uint256 => bool) public isEraDappRewardsClaimedSuccessfully;
    mapping(uint256 => bool) public isAddedToUnsuccess;
    uint256[] public unsuccessfulClaimsOfDappRewards;

    event Staked(address indexed user, uint256 val);
    event StakedInUtility(
        address indexed user,
        string indexed utility,
        uint256 val
    );
    event Unstaked(address indexed user, uint256 amount, bool immediate);
    event UnstakedFromUtility(
        address indexed user,
        string indexed utility,
        uint256 amount,
        bool immediate
    );
    event Withdrawn(address indexed user, uint256 val);
    event Claimed(address indexed user, uint256 amount);
    event ClaimedFromUtility(
        address indexed user,
        string indexed utility,
        uint256 amount
    );
    event HarvestRewards(
        address indexed user,
        string indexed utility,
        uint256 amount
    );
    event UnstakeError(
        string indexed utility,
        uint256 sum2unstake,
        uint256 indexed era,
        bytes indexed reason
    );
    event WithdrawUnbondedError(uint256 indexed _era, bytes indexed reason);
    event ClaimDappError(
        uint256 indexed amount,
        uint256 indexed era,
        bytes indexed reason
    );
    event SyncClaimDappError(
        uint256 indexed amount,
        uint256 indexed era,
        bytes indexed reason
    );
    event SetMinStakeAmount(address indexed sender, uint256 amount);
    event WithdrawRevenue(uint256 amount);
    event Synchronization(address indexed sender, uint256 indexed era);
    event FillUnstaking(address indexed sender, uint256 value);
    event FillRewardPool(address indexed sender, uint256 value);
    event FillUnbonded(address indexed sender, uint256 value);
    event ClaimDappSuccess(uint256 receivedRewards, uint256 indexed _era);
    event SyncClaimDappSuccess(uint256 receivedRewards, uint256 indexed _era);
    event WithdrawUnbondedSuccess(uint256 indexed _era);
    event UnstakeSuccess(uint256 indexed era, uint256 sum2unstake);
    event ClaimStakerSuccess(uint256 indexed era);
    event ClaimStakerError(uint256 indexed era, bytes indexed reason);
    event StakeSuccess(
        address indexed staker,
        string indexed utilityName,
        uint256 amount
    );
    event StakeError(
        address indexed staker,
        string indexed utilityName,
        uint256 amount,
        bytes reason
    );
    event UnlockSuccess();
    event UnlockError(
        string indexed utility,
        uint256 sum2unstake,
        uint256 indexed era,
        bytes indexed reason
    );
    event PeriodUpdateStakeSuccess(uint256 indexed period, string dappName);
    event BonusRewardsClaimSuccess(
        uint256 indexed period,
        string dappName,
        uint256 gain
    );
    event BonusRewardsClaimError(
        uint256 indexed period,
        string dappName,
        bytes reason
    );
    event WithdrawBonusRewards(
        address caller,
        uint256 indexed period,
        uint256 amount
    );
    event CleanUpExpiredEntriesSuccess(uint256 indexed period);
    event CleanUpExpiredEntriesError(uint256 indexed period, bytes reason);

    /// @notice get current period
    function currentPeriod() public view returns (uint256) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.period;
    }

    /// @notice get current era
    function currentEra() public view returns (uint256) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.era;
    }

    /// @notice get current subperiod
    /// @return "true" if current subperiod is "Voting"
    ///         "false" if current subperiod is "BuildAndEarn"
    function voteSubperiod() public view returns (bool) {
        DappsStaking.ProtocolState memory state = DAPPS_STAKING
            .protocol_state();
        return state.subperiod == DappsStaking.Subperiod.Voting;
    }
}
