// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";
import "../libraries/Errors.sol";

contract LiquidStakingAdmin is AccessControlUpgradeable, LiquidStakingStorage {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    /// @notice add new staker and save balances
    /// @param  _addr => user to add
    /// @param  _utility => user utility
    function addStaker(address _addr, string memory _utility) external {
        if (msg.sender != address(distr)) revert Err.OnlyNDistributorAllowed();

        if (!isStaker[_addr]) {
            isStaker[_addr] = true;
            stakers.push(_addr);
        }
        if (dapps[_utility].stakers[_addr].lastClaimedEra == 0)
            dapps[_utility].stakers[_addr].lastClaimedEra =
                this.currentEra() +
                1;
    }

    /// @notice set list with dapps names
    /// @param _dappsList dapps names
    function setDappsList(
        string[] memory _dappsList
    ) external payable onlyRole(MANAGER) {
        if (_dappsList.length == 0) revert Err.EmptyArray();
        dappsList = _dappsList;
    }

    /// @notice necessary for withdrawing bonus rewards and their further distribution
    function withdrawBonusRewards() external payable onlyRole(MANAGER) {
        if (bonusRewardsPool == 0) revert Err.EmptyBonusRewardPool();

        uint256 toSend = bonusRewardsPool;
        bonusRewardsPool = 0;

        payable(msg.sender).sendValue(toSend);

        emit WithdrawBonusRewards(msg.sender, this.currentPeriod(), toSend);
    }

    /// @notice add partner dapp
    function addDapp(
        string memory _dappName,
        address _dappAddr
    ) external payable onlyRole(MANAGER) {
        Dapp storage dapp = dapps[_dappName];
        if (dapp.dappAddress == address(0)) revert Err.DappAlreadyAdded();

        dapp.dappAddress = _dappAddr;
        isActive[_dappName] = true;
    }

    /// @notice switch dapp status active/inactive. Not available to stake to inactive dapp
    /// @param _dappName name of one of the available dapps
    function toggleDappAvailability(
        string memory _dappName
    ) external payable onlyRole(MANAGER) {
        isActive[_dappName] = !isActive[_dappName];
    }

    /// @notice set adapterDistributor address, to keep updated user balances in adapters
    function setAdaptersDistributor(
        address _adistr
    ) external payable onlyRole(MANAGER) {
        if (_adistr == address(0)) revert Err.ZeroAddress();

        adaptersDistr = IAdaptersDistributor(_adistr);
    }

    /// @notice sets min stake amount
    /// @param _amount => new min stake amount
    function setMinStakeAmount(uint _amount) public payable onlyRole(MANAGER) {
        if (_amount == 0) revert Err.ZeroAmount();

        minStakeAmount = _amount;
        emit SetMinStakeAmount(msg.sender, _amount);
    }

    /// @notice withdraw revenue
    /// @param _amount amount to withdraw
    function withdrawRevenue(
        uint256 _amount
    ) external payable onlyRole(MANAGER) {
        if (totalRevenue < _amount) revert Err.RevenuePoolInsufficientFunds();

        totalRevenue -= _amount;
        payable(msg.sender).sendValue(_amount);

        emit WithdrawRevenue(_amount);
    }

    /// @notice Withdraw rewards overage. Calculates offchain.
    ///         Formed when users use their nASTR tokens in defi protocols bypassing algem-adapters.
    function withdrawOverage(
        uint256 amount
    ) external payable onlyRole(MANAGER) {
        rewardPool -= amount;
        payable(msg.sender).sendValue(amount);
    }

    // READERS ////////////////////////////////////////////////////////////////////

    function getStaker(
        string memory _utility,
        address _user,
        uint256 _era
    )
        public
        view
        returns (
            uint256 eraBalance_,
            bool isZeroBalance_,
            uint256 rewards_,
            uint256 lastClaimedEra_
        )
    {
        Staker storage s = dapps[_utility].stakers[_user];
        eraBalance_ = s.eraBalance[_era];
        isZeroBalance_ = s.isZeroBalance[_era];
        rewards_ = s.rewards;
        lastClaimedEra_ = s.lastClaimedEra;
    }

    /// @notice returns user active withdrawals
    function getUserWithdrawals() external view returns (Withdrawal[] memory) {
        return withdrawals[msg.sender];
    }

    function getUserWithdrawalsArray(
        address _user
    ) external view returns (Withdrawal[] memory) {
        return withdrawals[_user];
    }

    /// @notice Get list with dapps names
    function getDappsList() external view returns (string[] memory) {
        return dappsList;
    }
}
