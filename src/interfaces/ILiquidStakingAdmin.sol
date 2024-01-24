// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILiquidStakingAdmin {
    function addDapp(string memory _dappName, address _dappAddr) external;
    function addPartner(address _partner) external;
    function addStaker(address _addr, string memory _utility) external;
    function setAdaptersDistributor(address _adistr) external;
    function setDappsList(string[] memory _dappsList) external;
    function setMaxDappsAmountPerCall(uint256 _maxDappsAmountPerCall) external;
    function toggleDappAvailability(string memory _dappName) external;
    function withdrawBonusRewards() external;
}
