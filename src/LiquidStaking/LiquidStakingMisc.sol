// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./LiquidStakingStorage.sol";

contract LiquidStakingMisc is LiquidStakingStorage {

    function getStaker(string memory _utility, address _user, uint256 _era) public view returns (uint256 eraBalance_, bool isZeroBalance_, uint256 rewards_, uint256 lastClaimedEra_) {
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

    function getUserWithdrawalsArray(address _user) external view returns (Withdrawal[] memory) {
        return withdrawals[_user];
    }

    /// @notice Get list with dapps names
    function getDappsList() external view returns (string[] memory) {
        return dappsList;
    }
}