// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";

contract LiquidStakingMigration is AccessControlUpgradeable, LiquidStakingStorage {

    /// @notice Temporary logic for updating params needed for unlocking process
    function updateParams(uint256 _lastUnstaked) external onlyRole(MANAGER) {
        lastUnstaked = _lastUnstaked;

        unlockingPeriod = 64800;
        maxUnlockingChunks = 8;
        chunkLen = unlockingPeriod / maxUnlockingChunks;
    }

    /// @dev Temporary logic for unlocking stucked ASTR in DappsStaking due to the migration process
    function unlockStucked(uint128 _amount) external onlyRole(MANAGER) {
        DAPPS_STAKING.unlock(_amount);

        emit UnlockSuccess();
    }

    /// @dev Temporary logic for correction user's unlocking periods
    function setBlockReq(
        address _user, 
        uint256 _withdrawalId, 
        uint256 _blockReq,
        uint256 _lag
    ) external onlyRole(MANAGER) {
        Withdrawal[] memory arr = withdrawals[_user];

        arr[_withdrawalId].blockReq = _blockReq;
        arr[_withdrawalId].lag = _lag;
    }
    
    // READERS ////////////////////////////////////////////////////////////////////

    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked {
            return ++_i;
        }
    }
}