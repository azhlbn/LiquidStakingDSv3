// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Err {
    error AlreadyClaimed();
    error ArraysLengthMismatch();
    error DappAlreadyAdded();
    error DappInactive();
    error EmptyArray();
    error EmptyBonusRewardPool();
    error EraUpdated();
    error EraYetToCome();
    error InsufficientAmount();
    error InsufficientValue();
    error NotEnoughRewards();
    error NoUtilitySpecified();
    error NothingToClaim();
    error OnlyNDistributorAllowed();
    error PartnerPoolsCanNotClaim();
    error ReentrantCall();
    error RevenuePoolInsufficientFunds();
    error RewardsPoolInsufficientFunds();
    error UnbondedPoolInsufficientFunds();
    error UnknownUtility();
    error ZeroAddress();
    error ZeroAmount();
}
