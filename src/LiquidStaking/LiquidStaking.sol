//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/proxy/Proxy.sol";
import "./LiquidStakingStorage.sol";
import "../interfaces/ILiquidStakingManager.sol";

contract LiquidStaking is AccessControlUpgradeable, LiquidStakingStorage, Proxy {
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    modifier whenNotPaused() {
        require(!paused || hasRole(MANAGER, msg.sender), "Contract paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _DNTname,
        string memory _utilName,
        address _distrAddr,
        address _adaptersDistr
    ) external initializer {
        require(_distrAddr.isContract(), "_distrAddr should be contract address");
        DNTname = _DNTname;
        utilName = _utilName;

        uint256 era = this.currentEra() - 1;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);
        
        withdrawBlock = DAPPS_STAKING.unlocking_period();

        distr = NDistributor(_distrAddr);

        lastUpdated = era;
        lastStaked = era;
        lastUnstaked = era;
        lastClaimed = era;

        dappsList.push(_utilName);
        isActive[_utilName] = true;
        dapps[_utilName].dappAddress = address(this);

        minStakeAmount = 10;
        maxDappsAmountPerCall = 20;

        adaptersDistr = IAdaptersDistributor(_adaptersDistr); 
    }

    function pause() external onlyRole(MANAGER) {
        require(!paused, "Already paused");
        paused = true;
    }

    function unpause() external onlyRole(MANAGER) {
        require(paused, "Not paused");
        paused = false;
    }

    function setLiquidStakingManager(address _liquidStakingManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_liquidStakingManager != address(0), "Address cant be null");
        require(_liquidStakingManager.isContract(), "Manager should be contract!");
        liquidStakingManager = _liquidStakingManager;
    }

    function _implementation() internal view override whenNotPaused returns (address) {
        /// @dev address(0) should changed on LiquidStakingManager contract address
        return ILiquidStakingManager(liquidStakingManager).getAddress(msg.sig);
    }

    /// @notice finish previously opened withdrawal
    /// @param _id => withdrawal index
    function withdraw(uint _id) external {
        _delegate(_implementation());
    }

    function setNftDistributor(address _nftDistr) external onlyRole(MANAGER) {
        nftDistr = INFTDistributor(_nftDistr);
    }

    receive() external override payable {}
}   
