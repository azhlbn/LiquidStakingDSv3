// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";

contract LiquidStakingMain is AccessControlUpgradeable, LiquidStakingStorage {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    /// @notice check arrays length
    /// @param _utilities => utilities to check length
    /// @param _amounts => amounts to check length
    modifier checkArrays(
        string[] memory _utilities,
        uint256[] memory _amounts
    ) {
        require(_utilities.length != 0, "No one utility selected");
        require(
            _utilities.length == _amounts.length,
            "Incorrect arrays length"
        );
        _;
    }

    /// @notice only distributors modifier
    modifier onlyDistributor() {
        require(
            msg.sender == address(distr) ||
                msg.sender == address(adaptersDistr),
            "Only for distributor!"
        );
        _;
    }

    /// @notice updates user rewards
    modifier updateRewards(address _user, string[] memory _utilities) {
        uint256 l = _utilities.length;

        // harvest rewards for current balances
        for (uint256 i; i < l; ++i) _harvestRewards(_utilities[i], _user);

        _;

        // update balances in utils
        for (uint256 i; i < l; ++i)
            _updateUserBalanceInUtility(_utilities[i], _user);
    }

    /// @notice updates global balances
    modifier updateAll() {
        uint256 _era = currentEra();
        if (lastUpdated != _era) {
            _updates(_era);
        }
        _;
    }

    /// @notice stake native tokens, receive equal amount of DNT
    /// @param _utilities => dapps utilities
    /// @param _amounts => amounts of tokens to stake
    function stake(
        string[] memory _utilities,
        uint256[] memory _amounts
    ) external payable checkArrays(_utilities, _amounts) updateAll {
        uint256 value = msg.value;

        uint256 utilitiesLength = _utilities.length;
        uint256 stakeAmount;

        for (uint256 i; i < utilitiesLength; ++i) {
            require(isActive[_utilities[i]], "Dapp not active");
            require(_amounts[i] >= minStakeAmount, "Not enough stake amount");

            stakeAmount += _amounts[i];
        }

        require(stakeAmount != 0, "Incorrect amounts");
        require(value >= stakeAmount, "Incorrect value");

        eraBuffer[0] += stakeAmount;
        uint256 _era = currentEra();

        if (!isStaker[msg.sender]) {
            isStaker[msg.sender] = true;
        }

        totalBalance += stakeAmount;

        // send back the diff
        if (value > stakeAmount)
            payable(msg.sender).sendValue(value - stakeAmount);

        // increase total stake amount and for msg.sender for current subperiod
        _updateSubperiodStakes(int256(stakeAmount));

        // lock total stake amount to further stake
        DAPPS_STAKING.lock(uint128(stakeAmount));

        for (uint256 i; i < utilitiesLength; ++i) {
            if (dapps[_utilities[i]].stakers[msg.sender].lastClaimedEra == 0)
                dapps[_utilities[i]].stakers[msg.sender].lastClaimedEra = _era + 1;

            if (_amounts[i] != 0) {
                string memory _utility = _utilities[i];
                uint256 amount = _amounts[i];                

                // stake ASTR for each dapp
                DAPPS_STAKING.stake(
                    DappsStaking.SmartContract(
                        DappsStaking.SmartContractType.EVM,
                        abi.encodePacked(dapps[_utility].dappAddress)
                    ),
                    uint128(amount)
                );

                distr.issueDnt(msg.sender, amount, _utility, DNTname);

                dapps[_utility].stakedBalance += amount;

                emit StakedInUtility(msg.sender, _utility, amount);
            }
        } // prettier-ignore

        emit Staked(msg.sender, stakeAmount);
    }

    /// @notice unstake tokens from dapps
    /// @param _utilities => dapps utilities
    /// @param _amounts => amounts of tokens to unstake
    /// @param _immediate => receive tokens from unstaking pool, create a withdrawal otherwise
    function unstake(
        string[] memory _utilities,
        uint256[] memory _amounts,
        bool _immediate
    ) external checkArrays(_utilities, _amounts) updateAll {
        uint256 totalUnstaked;
        uint256 era = currentEra();

        uint256 utilitiesLength = _utilities.length;
        for (uint256 i; i < utilitiesLength; ++i) {
            require(haveUtility[_utilities[i]], "Unknown utility");

            if (_amounts[i] != 0) {
                string memory _utility = _utilities[i];
                uint256 _amount = _amounts[i];

                uint256 userDntBalance = distr.getUserDntBalanceInUtil(
                    msg.sender,
                    _utility,
                    DNTname
                );

                require(
                    userDntBalance >= _amount,
                    "Not enough nASTR in utility"
                );

                Dapp storage dapp = dapps[_utility];
                _harvestRewards(_utility, msg.sender);
                _updatePreviousEra(dapp, era, _amount);

                dapp.sum2unstake += _amount;
                totalBalance -= _amount;
                dapp.stakedBalance -= _amount;

                distr.removeDnt(msg.sender, _amount, _utility, DNTname);

                if (_immediate) {
                    require(
                        unstakingPool >= _amount,
                        "Unstaking pool drained!"
                    );
                    uint256 fee = _amount / 100; // 1% immediate unstaking fee
                    totalRevenue += fee;
                    unstakingPool -= _amount;
                    payable(msg.sender).sendValue(_amount - fee);
                } else {
                    uint256 _lag;

                    if (lastUnstaked * 10 + (withdrawBlock * 10) >> 2 > era * 10) {
                        _lag = lastUnstaked * 10 + (withdrawBlock * 10) >> 2 - era * 10; 
                    } // prettier-ignore

                    // create a withdrawal to withdraw_unbonded later
                    withdrawals[msg.sender].push(
                        Withdrawal({val: _amount, eraReq: era, lag: _lag})
                    );
                }

                totalUnstaked += _amount;

                emit UnstakedFromUtility(
                    msg.sender,
                    _utility,
                    _amount,
                    _immediate
                );
            }
        }
        if (totalUnstaked != 0) {
            _updateSubperiodStakes(~int256(totalUnstaked) + 1); // convert arg to negative number

            eraBuffer[1] += totalUnstaked;

            emit Unstaked(msg.sender, totalUnstaked, _immediate);
        }
    }

    /// @notice claim user rewards from utilities
    /// @param _utilities => utilities from claim
    /// @param _amounts => amounts from claim
    function claim(
        string[] memory _utilities,
        uint256[] memory _amounts
    )
        external
        checkArrays(_utilities, _amounts)
        updateAll
        updateRewards(msg.sender, _utilities)
    {
        _claim(_utilities, _amounts);
    }

    /// @notice claim all user rewards from all utilities (without adapters)
    function claimAll() external updateAll {
        string[] memory _distrutilities = distr.listUserUtilitiesInDnt(
            msg.sender,
            DNTname
        );
        uint256 l = _distrutilities.length;

        uint256[] memory _amounts = new uint256[](l + 1);
        string[] memory _utilities = new string[](l + 1);

        // basically we just need to append one utility :(
        for (uint i; i < l; ++i) {
            _utilities[i] = _distrutilities[i];
        }
        _utilities[l] = "AdaptersUtility";

        // update user rewards and push to _amounts[]
        for (uint256 i; i < l + 1; ++i) {
            _harvestRewards(_utilities[i], msg.sender);
            _amounts[i] = dapps[_utilities[i]].stakers[msg.sender].rewards;
        }
        _claim(_utilities, _amounts);

        // update last user balance
        for (uint256 i; i < l; ++i)
            _updateUserBalanceInUtility(_utilities[i], msg.sender);
    }

    /// @notice finish previously opened withdrawal
    /// @param _id => withdrawal index
    function withdraw(uint _id) external updateAll {
        Withdrawal storage withdrawal = withdrawals[msg.sender][_id];
        uint val = withdrawal.val;
        uint era = currentEra();

        require(withdrawal.eraReq != 0, "Withdrawal already claimed");
        require(
            era * 10 - withdrawal.eraReq * 10 >=
                withdrawBlock * 10 + withdrawal.lag,
            "Not enough eras passed!"
        );
        require(unbondedPool >= val, "Unbonded pool drained!");

        unbondedPool -= val;
        withdrawal.eraReq = 0;

        payable(msg.sender).sendValue(val);
        emit Withdrawn(msg.sender, val);
    }

    /// @notice global updates function
    /// @param _era => era to update
    function _updates(uint256 _era) internal {
        _globalWithdraw(_era);
        _claimFromDapps(_era);
        _claimDapp(_era);
        _periodUpdate();
        _globalUnstake(_era);
        lastUpdated = _era;
    }

    // ADMIN LOGIC ////////////////////////////////////////////////////////////////

    /// @notice utility function in case of excess gas consumption
    function sync(uint _era) external payable onlyRole(MANAGER) {
        require(_era > lastUpdated, "Era passed");
        require(_era <= currentEra(), "Era yet to come");
        _updates(_era);

        emit Synchronization(msg.sender, _era);
    }

    /// @notice utility harvest function
    function syncHarvest(
        address _user,
        string[] memory _utilities
    ) external onlyRole(MANAGER) updateRewards(_user, _utilities) {}

    /// @notice update last user balance
    /// @param _utility => utility
    /// @param _user => user address
    function updateUserBalanceInUtility(
        string memory _utility,
        address _user
    ) external onlyDistributor {
        _updateUserBalanceInUtility(_utility, _user);
    }

    /// @notice function to update last user balance in adapters
    /// @param _utility => "AdaptersUtility" utility
    /// @param _user => user address
    function updateUserBalanceInAdapter(
        string memory _utility,
        address _user
    ) external onlyDistributor {
        require(_user != address(0), "Zero address alarm!");
        uint256 _amount = adaptersDistr.getUserBalanceInAdapters(_user);
        _updateUserBalance(_utility, _user, _amount);
    }

    // INTERNAL LOGIC /////////////////////////////////////////////////////////////

    /// @notice claim staker rewards from all dapps
    /// @param _era => latest era to claim
    function _claimFromDapps(uint256 _era) internal {
        if (lastUpdated >= _era) return;

        uint256 balanceBefore = address(this).balance;

        try DAPPS_STAKING.claim_staker_rewards() {
            emit ClaimStakerSuccess(_era);
        } catch (bytes memory reason) {
            emit ClaimStakerError(_era, reason);
        }

        uint256 balanceAfter = address(this).balance;

        uint256 receivedRewards = balanceAfter - balanceBefore;
        uint256 eras = _era - lastUpdated;

        uint256 allErasBalance = lastEraTotalBalance *
            eras + eraBuffer[0] * (eras - 1) - eraBuffer[1] * (eras - 1); 

        if (allErasBalance != 0) {
            uint256[2] memory erasData = nftDistr.getErasData(
                lastUpdated - 1,
                _era - 1
            );

            uint256 rewardsK = receivedRewards * REWARDS_PRECISION / allErasBalance; 
            uint256 nftRevenue = (rewardsK * erasData[1]) / 
                (100 * REWARDS_PRECISION);
            uint256 defaultRevenue = rewardsK * REVENUE_FEE * (allErasBalance - erasData[0]) / (100 * REWARDS_PRECISION); 

            for (uint256 i = lastUpdated; i < _era; i = _uncheckedIncr(i)) {
                accumulatedRewardsPerShare[i] = rewardsK;
            }

            uint256 toUnstaking = receivedRewards / 100;
            totalRevenue += nftRevenue + defaultRevenue; // 9% of era reward s goes to revenue pool
            unstakingPool += toUnstaking; // 1% of era rewards goes to unstaking pool
            rewardPool += receivedRewards - nftRevenue - defaultRevenue - toUnstaking; 
        } else totalRevenue += receivedRewards;

        (eraBuffer[0], eraBuffer[1]) = (0, 0);

        // update last era balance
        // last era balance = balance that participates in the current era
        lastEraTotalBalance = distr.totalDnt(DNTname);
    } // prettier-ignore

    /// @notice claim dapp rewards for this contract
    /// @dev the function collects rewards only for the LiquidStaking contract
    /// @param _currentEra => era to claim dapp rewards
    function _claimDapp(uint _currentEra) internal {
        for (uint256 era = lastUpdated; era < _currentEra; era = _uncheckedIncr(era)) {
            uint256 balanceBefore = address(this).balance;
            try DAPPS_STAKING.claim_dapp_reward(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(address(this))
                ), 
                uint128(era)
            ) {
                emit ClaimDappSuccess(address(this).balance - balanceBefore, _currentEra);
            } catch (bytes memory reason) {
                emit ClaimDappError(accumulatedRewardsPerShare[era], era, reason);
            }
        } // prettier-ignore
    }

    /// @notice withdraw unbonded tokens
    /// @param _era => desired era
    function _globalWithdraw(uint256 _era) internal {
        uint256 balanceBefore = address(this).balance;

        try DAPPS_STAKING.claim_unlocked() {
            unbondedPool += address(this).balance - balanceBefore;
            emit WithdrawUnbondedSuccess(_era);
        } catch (bytes memory reason) {
            emit WithdrawUnbondedError(_era, reason);
        }
    }

    /// @notice ustake tokens from not yet updated eras from all dapps
    /// @param _era => latest era to update
    function _globalUnstake(uint256 _era) internal {
        if (_era * 10 < (lastUnstaked * 10 + (withdrawBlock * 10)) >> 2) return;

        // unstake from all dapps
        uint256 l = dappsList.length;
        for (uint256 i; i < l; i = _uncheckedIncr(i)) {
            _globalUnstakeForUtility(dappsList[i], _era);
        }

        lastUnstaked = _era;
    }

    /// @notice ustake tokens from not yet updated eras from utility
    /// @param _utility => utility to unstake
    /// @param _era => latest era to update
    function _globalUnstakeForUtility(
        string memory _utility,
        uint256 _era
    ) internal {
        Dapp storage dapp = dapps[_utility];

        if (dapp.sum2unstake == 0) return;
        if (!isActive[_utility] && _era > deactivationEra[_utility]) return;

        try DAPPS_STAKING.unstake(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapp.dappAddress)
                ),
                uint128(dapp.sum2unstake)
            )
        {
            try DAPPS_STAKING.unlock(uint128(dapp.sum2unstake)) {
                dapp.sum2unstake = 0;
                emit UnlockSuccess();
            } catch (bytes memory reason) {
                emit UnlockError(_utility, dapp.sum2unstake, _era, reason);
            }
            emit UnstakeSuccess(_era, dapp.sum2unstake);
        } catch (bytes memory reason) {
            emit UnstakeError(_utility, dapp.sum2unstake, _era, reason);
        } // prettier-ignore
    }

    /// @notice function to update last user balance in utility
    /// @param _utility => utility
    /// @param _user => user address
    function _updateUserBalanceInUtility(
        string memory _utility,
        address _user
    ) internal {
        require(_user != address(0), "Zero address alarm!");
        if (keccak256(bytes(_utility)) == keccak256("AdaptersUtility")) return;
        uint256 _amount = distr.getUserDntBalanceInUtil(
            _user,
            _utility,
            DNTname
        );
        _updateUserBalance(_utility, _user, _amount);
    }

    /// @notice function to update user balance in next era
    /// @param _utility => utility
    /// @param _user => user address
    /// @param _amount => new era balance
    function _updateUserBalance(
        string memory _utility,
        address _user,
        uint256 _amount
    ) internal {
        uint _era = currentEra() + 1;

        Staker storage staker = dapps[_utility].stakers[_user];

        if (dapps[_utility].stakers[_user].lastClaimedEra == 0)
            dapps[_utility].stakers[_user].lastClaimedEra = _era;

        // add to mapping
        staker.eraBalance[_era] = _amount;
        staker.isZeroBalance[_era] = _amount != 0 ? false : true;
    }

    /// @notice function to update the user's balance upon unstaking in the current era
    /// @param dapp => <Dapp struct> to update user balance.
    /// @param era => current era.
    /// @param amount => unstaking amount.
    function _updatePreviousEra(
        Dapp storage dapp,
        uint256 era,
        uint256 amount
    ) internal {
        if (!dapp.stakers[msg.sender].isZeroBalance[era]) {
            if (dapp.stakers[msg.sender].eraBalance[era] > amount)
                dapp.stakers[msg.sender].eraBalance[era] -= amount;
            else {
                dapp.stakers[msg.sender].eraBalance[era] = 0;
                dapp.stakers[msg.sender].isZeroBalance[era] = true;
            }
        }
    }

    /// @notice claim rewards by user utilities
    /// @param _utilities => utilities from claim
    /// @param _amounts => amounts from claim
    function _claim(
        string[] memory _utilities,
        uint256[] memory _amounts
    ) internal {
        require(!isPartner[msg.sender], "ClaimNotAllowedForPartnerPools");

        uint256 l = _utilities.length;
        uint256 transferAmount;

        for (uint256 i; i < l; ++i) {
            if (_amounts[i] != 0) {
                Dapp storage dapp = dapps[_utilities[i]];
                require(
                    dapp.stakers[msg.sender].rewards >= _amounts[i],
                    "Not enough rewards!"
                );
                require(rewardPool >= _amounts[i], "Rewards pool drained");

                rewardPool -= _amounts[i];
                dapp.stakers[msg.sender].rewards -= _amounts[i];
                totalUserRewards[msg.sender] -= _amounts[i];
                transferAmount += _amounts[i];

                emit ClaimedFromUtility(msg.sender, _utilities[i], _amounts[i]);
            }
        }

        require(transferAmount != 0, "Nothing to claim");
        payable(msg.sender).sendValue(transferAmount);

        emit Claimed(msg.sender, transferAmount);
    }

    /// @notice harvest user rewards
    /// @param _utility => utility to harvest
    /// @param _user => user address
    function _harvestRewards(string memory _utility, address _user) internal {
        // calculate unclaimed user rewards
        (
            uint256[2] memory userData,
            uint8 newEraComission,
            uint256 userEraBalance,
            bool _updateUser
        ) = _calcUserRewards(_utility, _user);
        if (_updateUser) {
            // update all structures for storing balances and fees in specific eras to actual values
            dapps[_utility].stakers[_user].eraBalance[lastUpdated] = userEraBalance; // prettier-ignore
            dapps[_utility].stakers[_user].isZeroBalance[lastUpdated] = userEraBalance != 0 ? false : true; // prettier-ignore
            nftDistr.updateUser(_utility, _user, lastUpdated - 1, userData[0]);
            nftDistr.updateUserFee(_user, newEraComission, lastUpdated - 1);
        }

        if (dapps[_utility].stakers[_user].lastClaimedEra != 0)
            dapps[_utility].stakers[_user].lastClaimedEra = lastUpdated;

        if (userData[1] == 0) return;

        // update user rewards
        dapps[_utility].stakers[_user].rewards += userData[1];
        totalUserRewards[_user] += userData[1];
        emit HarvestRewards(_user, _utility, userData[1]);
    }

    /// @dev Updates subperiod stakes. Increase in stake case and decrease if unstake
    /// @param _amount => amount to increase or decrease stake size. Positive if its a stake and negative if its an unstake.
    function _updateSubperiodStakes(int256 _amount) internal {
        uint256 currentPeriodNumber = currentPeriod();
        Period storage period = periods[currentPeriodNumber];

        if (voteSubperiod()) {
            period.voteStake = uint256(int256(period.voteStake) + _amount);
            period.buidAndEarnStake = uint256(int256(period.buidAndEarnStake) + _amount);
            periodsStakes[msg.sender][currentPeriodNumber][0] = uint256(int256(periodsStakes[msg.sender][currentPeriodNumber][0]) + _amount);
            periodsStakes[msg.sender][currentPeriodNumber][1] = uint256(int256(periodsStakes[msg.sender][currentPeriodNumber][1]) + _amount);
        } else {
            period.buidAndEarnStake = uint256(int256(period.buidAndEarnStake) + _amount);
            periodsStakes[msg.sender][currentPeriodNumber][1] = uint256(int256(periodsStakes[msg.sender][currentPeriodNumber][1]) + _amount);
        } // prettier-ignore

        require(
            period.voteStake <= period.buidAndEarnStake,
            "Unstake size too big"
        );
    }

    /// @notice performed at the beginning of new period and restakes ASTR
    function _periodUpdate() internal {
        uint256 currentPeriodNumber = currentPeriod();
        Period storage period = periods[currentPeriodNumber];

        if (!period.initialized) return;

        period.initialized = true;

        // Used to cleanup all expired contract stake entries
        try DAPPS_STAKING.cleanup_expired_entries() {
            emit CleanUpExpiredEntriesSuccess(currentPeriodNumber);
        } catch (bytes memory reason) {
            emit CleanUpExpiredEntriesError(currentPeriodNumber, reason);
        }

        // at the beginning of the period contract make restakes at all dapps and claim bonus rewards
        for (uint256 idx; idx < dappsList.length; idx = _uncheckedIncr(idx)) {
            try DAPPS_STAKING.stake(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapps[dappsList[idx]].dappAddress)
                ),
                uint128(dapps[dappsList[idx]].stakedBalance)
            ) {
                emit PeriodUpdateStakeSuccess(currentPeriodNumber, dappsList[idx]);
            } catch (bytes memory reason) {
                emit PeriodUpdateStakeError(currentPeriodNumber, dappsList[idx], reason);
            } // prettier-ignore

            // claim bonus rewards logic
            uint256 balanceBefore = address(this).balance;
            try DAPPS_STAKING.claim_bonus_reward(
                DappsStaking.SmartContract(
                    DappsStaking.SmartContractType.EVM,
                    abi.encodePacked(dapps[dappsList[idx]].dappAddress)
                )
            ) {
                uint256 gain = address(this).balance - balanceBefore;
                bonusRewardsPool += gain;
                emit BonusRewardsClaimSuccess(currentPeriodNumber, dappsList[idx], gain);
            } catch (bytes memory reason) {
                emit BonusRewardsClaimError(currentPeriodNumber, dappsList[idx], reason);
            } // prettier-ignore
        }
    }

    // READERS ////////////////////////////////////////////////////////////////////

    /// @notice preview all eser rewards from utility at current era
    /// @param _utility => utility
    /// @param _user => user address
    /// @return userRewards => unclaimed user rewards from utility
    function previewUserRewards(
        string memory _utility,
        address _user
    ) external view returns (uint256) {
        (uint256[2] memory userData, , , ) = _calcUserRewards(_utility, _user);
        return userData[1] + dapps[_utility].stakers[_user].rewards;
    }

    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked {
            return ++_i;
        }
    }

    /// @notice clculate unclaimed user rewards from utility
    /// @param _utility => utility name
    /// @param _user => user address
    /// @return userData => [0] - last user balance with nft | [1] - total rewards
    /// @return userEraFee => last user comission
    /// @return needUpdated => flag to update user data; if true - need to update
    /// @custom:defimoon-note all balance and fee calculations are done inside the function
    /// * because we need the function to be a <view> so that we can calculate
    /// * the most up-to-date rewards for the user without the need for a claim
    function _calcUserRewards(
        string memory _utility,
        address _user
    ) internal view returns (uint256[2] memory userData, uint8, uint256, bool) {
        Staker storage user = dapps[_utility].stakers[_user];

        if (
            isPartner[_user] ||
            user.lastClaimedEra >= lastUpdated ||
            user.lastClaimedEra == 0
        ) return (userData, 0, 0, false);

        (userData[0], ) = nftDistr.getUserEraBalance(
            _utility,
            _user,
            user.lastClaimedEra - 1
        );
        uint8 userEraFee = nftDistr.getUserEraFee(
            _user,
            user.lastClaimedEra - 1
        );
        if (userEraFee == 0) userEraFee = REVENUE_FEE;

        uint256 userEraBalance = user.eraBalance[user.lastClaimedEra];
        bool isUnique = nftDistr.isUnique(_utility);

        for (uint256 i = user.lastClaimedEra; i < lastUpdated; i = _uncheckedIncr(i)) {
            if (userEraBalance != 0) {
                // calcutating user rewards with user era fee
                if (userData[0] != 0 && isUnique)
                    userEraFee = nftDistr.getBestUtilFee(_utility, userEraFee);
                uint256 userEraRewards = (userEraBalance *
                    accumulatedRewardsPerShare[i]) / REWARDS_PRECISION;
                userData[1] +=
                    (userEraRewards * (100 - userEraFee - UNSTAKING_FEE)) / 100;
            }

            // using <eraBalance> and <isZeroBalance> determine the user's balance in the next era
            if (user.eraBalance[i + 1] == 0) {
                if (user.isZeroBalance[i + 1]) userEraBalance = 0;
            } else userEraBalance = user.eraBalance[i + 1];

            // determine the user's balance with nft in the next era
            (uint256 _userBalanceWithNft, bool _isZeroBalanceWithNft) = nftDistr
                .getUserEraBalance(_utility, _user, i);
            if (_userBalanceWithNft == 0) {
                if (_isZeroBalanceWithNft) userData[0] = 0;
            } else userData[0] = _userBalanceWithNft;

            // determine the user's fee in the next era
            uint8 _userNextEraFee = nftDistr.getUserEraFee(_user, i);
            if (_userNextEraFee != 0) userEraFee = _userNextEraFee;
        } // prettier-ignore

        return (userData, userEraFee, userEraBalance, true);
    }
}
