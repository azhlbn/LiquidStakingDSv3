// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "./LiquidStakingStorage.sol";

contract LiquidStakingMigration is AccessControlUpgradeable, LiquidStakingStorage {

    /// @dev Adjust the user's eraReq in case the unbonding period crosses the migration process
    function syncUnbondingEra(address user, uint256 firstV3Era) external onlyRole(MANAGER) {
        Withdrawal[] memory arr = withdrawals[user];

        for (uint256 i; i < arr.length; i = _uncheckedIncr(i)) {
            uint256 unbondedEraX10 = arr[i].eraReq * 10 + arr[i].lag + withdrawBlock * 10; // era in which unbonding period ends

            if (unbondedEraX10 >= firstV3Era * 10 && arr[i].lag != 50) {
                Withdrawal storage withdrawal = withdrawals[user][i];
                withdrawal.eraReq = firstV3Era - withdrawBlock - 5;
                withdrawal.lag = 50; // necessary to prevent double spending

                temporaryUnbondedPool += withdrawal.val;
            }
        }
    }

    /// @dev Need to be called immediately after migration to sync unbondedPool
    function migration() external onlyRole(MANAGER) {
        unbondedPool += temporaryUnbondedPool;
    }
    
    // READERS ////////////////////////////////////////////////////////////////////

    /// @dev check if passed user address has any unbonding periods that are passed on during migration
    function isSyncUnbondingEraNeeded(address user, uint256 firstV3Era) external view returns (bool) {
        Withdrawal[] memory arr = withdrawals[user];

        for (uint256 i; i < arr.length; i = _uncheckedIncr(i)) {
            if (arr[i].eraReq * 10 + arr[i].lag + withdrawBlock * 10 >= firstV3Era * 10 && arr[i].lag != 50) return true;
        }

        return false;
    }

    function _uncheckedIncr(uint256 _i) internal pure returns (uint256) {
        unchecked {
            return ++_i;
        }
    }
}