// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";

import "./DeployStorage.sol";

contract UnlockPeriodsTest is DeployStorage, Test {
    address deployer;
    address alice;
    address bob;

    // start from 1 period
    uint256 startBlock = 7200 * 3;

    function setUp() public {
        deployer = vm.addr(1);
        alice = vm.addr(2);
        bob = vm.addr(3);

        vm.deal(deployer, ~uint256(0));
        vm.deal(alice, ~uint256(0));
        vm.deal(bob, ~uint256(0));

        _deployLiquidStakingContracts();
        _updateParams();
    }

    /// @dev Testing unlocking periods for two users, who staked in different time
    function test_withdraw() public {
        uint256 stake = 1000e18;
        uint256 delay = ls.unlockingPeriod() + ls.chunkLen();
        uint256 invalidBlockNumber = startBlock + delay - 1;
        uint256 validBlockNumber = startBlock + delay;
        uint256 validBlockNumberForBob = validBlockNumber + delay;

        vm.startPrank(alice);
        _stake(stake);
        assertEq(nastr.balanceOf(alice), stake);

        _unstake(stake);

        // one era and chunk period passed
        vm.roll(startBlock + 8100);

        // for unlock calling and state updates
        liquid.sync(liquid.currentEra());  

        vm.stopPrank();

        vm.prank(bob);
        _stake(stake);
        
        vm.prank(alice);
        vm.roll(invalidBlockNumber);
        vm.expectRevert("Not enough blocks passed!");
        ls.withdraw(0);

        vm.prank(alice);
        vm.roll(validBlockNumber);
        ls.withdraw(0);

        assertEq(nastr.balanceOf(alice), 0);

        vm.startPrank(bob);

        _unstake(stake);
        vm.expectRevert("Not enough blocks passed!");
        ls.withdraw(0);

        vm.roll(validBlockNumberForBob);
        ls.withdraw(0);

        assertEq(nastr.balanceOf(bob), 0);
    }

    function test_stake() public {
        uint256 stake = 1000e18;

        vm.prank(alice);
        _stake(stake);

        vm.prank(bob);
        _stake(stake);

        assertEq(nastr.balanceOf(alice), stake);
        assertEq(nastr.balanceOf(bob), stake);
    }

    function _stake(uint256 amount) private {
        string[] memory utils = new string[](1);
        uint256[] memory amounts = new uint256[](1);

        (utils[0], amounts[0]) = ("LiquidStaking", amount);

        liquid.stake{value: amount}(utils, amounts);
    }

    function _unstake(uint256 amount) private {
        string[] memory utils = new string[](1);
        uint256[] memory amounts = new uint256[](1);

        (utils[0], amounts[0]) = ("LiquidStaking", amount);

        liquid.unstake(utils, amounts, false);
    }

    function _updateParams() private prank(deployer) {
        LiquidStakingMigration(address(ls)).updateParams(block.number);

        assertEq(ls.unlockingPeriod(), 64800);
        assertEq(ls.maxUnlockingChunks(), 8);
        assertEq(ls.chunkLen(), 64800 / 8);
    }

    function _deployLiquidStakingContracts() private prank(deployer) {
        vm.roll(7200 * 3);

        admin = new ProxyAdmin();

        // Deploy mock DappsStaking to precompiled address to avoid contract changes
        ds = new MockDappsStaking();
        bytes memory dsCode = address(ds).code;
        vm.etch(0x0000000000000000000000000000000000005001, dsCode);
        ds = MockDappsStaking(0x0000000000000000000000000000000000005001);
        vm.deal(address(ds), ~uint256(0));

        lsImpl = new LiquidStaking();
        managerImpl = new LiquidStakingManager();
        distrImpl = new NDistributor();
        nastrImpl = new NASTR();
        nftdistrImpl = new NFTDistributor();
        adistrImpl = new AdaptersDistributor();
        nftImpl = new AlgemLiquidStakingDiscount();

        lsProxy = new TransparentUpgradeableProxy(address(lsImpl), address(admin), "");
        managerProxy = new TransparentUpgradeableProxy(address(managerImpl), address(admin), "");
        distrProxy = new TransparentUpgradeableProxy(address(distrImpl), address(admin), "");
        nastrProxy = new TransparentUpgradeableProxy(address(nastrImpl), address(admin), "");
        nftdistrProxy = new TransparentUpgradeableProxy(address(nftdistrImpl), address(admin), "");
        adistrProxy = new TransparentUpgradeableProxy(address(adistrImpl), address(admin), "");
        nftProxy = new TransparentUpgradeableProxy(address(nftImpl), address(admin), "");

        manager = LiquidStakingManager(address(managerProxy));
        manager.initialize();

        distr = NDistributor(address(distrProxy));
        distr.initialize();
        distr.addUtility("LiquidStaking");        

        nastr = NASTR(address(nastrProxy));
        nastr.initialize(address(distr));

        distr.changeDntAddress("nASTR", address(nastr));
        distr.grantRole(keccak256("MANAGER_CONTRACT"), address(nastr));
        distr.grantRole(keccak256("MANAGER_CONTRACT"), address(lsProxy));
        distr.grantRole(keccak256("MANAGER"), address(nastr));
        distr.setLiquidStaking(address(lsProxy));

        ls = LiquidStaking(payable(address(lsProxy)));
        ls.initialize(
            "nASTR",
            "LiquidStaking",
            address(distr),
            address(adistrProxy)
        );

        liquid = LiquidStakingMain(address(ls));

        nftdistr = NFTDistributor(address(nftdistrProxy));
        nftdistr.initialize(
            address(distr),
            address(nastr),
            address(ls),
            address(adistrProxy)
        );

        nastr.setNftDistributor(address(nftdistr));

        adistr = AdaptersDistributor(address(adistrProxy));
        adistr.initialize(address(ls));
        adistr.setNftDistributor(address(nftdistr));

        ls.setLiquidStakingManager(address(manager));
        ls.grantRole(keccak256("MANAGER"), address(nftdistr));
        ls.grantRole(keccak256("MANAGER"), address(alice));
        LiquidStaking(payable(address(ls))).setNftDistributor(address(nftdistr));

        lsMain = new LiquidStakingMain();
        lsAdmin = new LiquidStakingAdmin();
        lsMigration = new LiquidStakingMigration();

        manager.addSelectorsBatch(
            selectorsMain,
            address(lsMain)
        );

        manager.addSelectorsBatch(
            selectorsAdmin,
            address(lsAdmin)
        );

        manager.addSelectorsBatch(
            selectorsMigration,
            address(lsMigration)
        );

        nft = AlgemLiquidStakingDiscount(address(nftProxy));
        nft.initialize(
            "ALSD NFT",
            "ALSD",
            "baseUri",
            nftdistr
        );
        nft.changeMaxSupply(100);
        nftdistr.addUtility(address(nft), 8, false);
        nftdistr.grantRole(keccak256("TOKEN_CONTRACT"), address(nft));
        nftdistr.grantRole(0x0000000000000000000000000000000000000000000000000000000000000000, address(ls));

        console2.log("LS address", address(ls));
        console2.log("nASTR address", address(nastr));
        console2.log("Distr address", address(distr));
    }

    modifier prank(address addr) {
        vm.startPrank(addr);
        _;
        vm.stopPrank();
    }
}