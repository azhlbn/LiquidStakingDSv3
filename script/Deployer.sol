// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import {Script, console2} from "forge-std/Script.sol";
import {LiquidStaking} from "../src/LiquidStaking/LiquidStaking.sol";
import {LiquidStakingManager} from "../src/LiquidStaking/LiquidStakingManager.sol";
import {LiquidStakingMain} from "../src/LiquidStaking/LiquidStakingMain.sol";
import {LiquidStakingAdmin} from "../src/LiquidStaking/LiquidStakingAdmin.sol";
import {LiquidStakingMisc} from "../src/LiquidStaking/LiquidStakingMisc.sol";
import {NDistributor} from "../src/NDistributor.sol";
import {NASTR} from "../src/NASTR.sol";
import {NFTDistributor} from "../src/NFTDistributor.sol";
import {AdaptersDistributor} from "../src/AdaptersDistributor.sol";

contract Deployer is Script {
    ProxyAdmin admin;

    TransparentUpgradeableProxy lsProxy;
    TransparentUpgradeableProxy managerProxy;
    TransparentUpgradeableProxy distrProxy;
    TransparentUpgradeableProxy nastrProxy;
    TransparentUpgradeableProxy nftdistrProxy;
    TransparentUpgradeableProxy adistrProxy;

    LiquidStaking lsImpl;
    LiquidStakingManager managerImpl;
    NDistributor distrImpl;
    NASTR nastrImpl;
    NFTDistributor nftdistrImpl;
    AdaptersDistributor adistrImpl;

    LiquidStaking ls;
    LiquidStakingManager manager;
    NDistributor distr;
    NASTR nastr;
    NFTDistributor nftdistr;
    AdaptersDistributor adistr;

    LiquidStakingMain lsMain;
    LiquidStakingAdmin lsAdmin;
    LiquidStakingMisc lsMisc;

    bytes4[] selectorsMain = [
        bytes4(0x59b40f41), bytes4(0xa217fddf), bytes4(0x40bf8a8d), bytes4(0x5f1554e3), bytes4(0x1b2df850), bytes4(0x4421bd1e), bytes4(0x86b3cd26), bytes4(0x59601ebc), bytes4(0xa2ce0f4a), bytes4(0xe2e836f8), bytes4(0x0c48b5aa), bytes4(0x54b057f9), bytes4(0x1f19014b), bytes4(0xd1058e59), bytes4(0x00179fbd), bytes4(0x973628f6), bytes4(0x06040618), bytes4(0xdcf425df), bytes4(0xda3bc958), bytes4(0x2a14d8f4), bytes4(0x6bbea766), bytes4(0x05e2a217), bytes4(0xc21a7276), bytes4(0xeb51a44c), bytes4(0x1dc00785), bytes4(0xf128f631), bytes4(0x2ea31bf6), bytes4(0xc4e137e7), bytes4(0xf16ca2e4), bytes4(0x248a9ca3), bytes4(0x2f2ff15d), bytes4(0x91d14854), bytes4(0x6f68f2e9), bytes4(0xc8902a21), bytes4(0x0f24ca7d), bytes4(0x8c0f9aac), bytes4(0x6f1e8533), bytes4(0x2e4a4a17), bytes4(0xadc1b956), bytes4(0xe77ee345), bytes4(0x12a12a06), bytes4(0x5495ec81), bytes4(0xd0b06f5d), bytes4(0x5ca5914e), bytes4(0xe09c1954), bytes4(0x1bb5e2dc), bytes4(0x078aebd5), bytes4(0xf1887684), bytes4(0xbd1bbd3b), bytes4(0xa5ae02ac), bytes4(0xc3b49d04), bytes4(0x4d617451), bytes4(0x5c975abb), bytes4(0xea4a1104), bytes4(0x05e20083), bytes4(0xb8d7cac9), bytes4(0x36568abe), bytes4(0xd547741f), bytes4(0x66666aa9), bytes4(0xa22eae1b), bytes4(0xfd5e6dd1), bytes4(0x16934fc4), bytes4(0xaf66c36b), bytes4(0x01ffc9a7), bytes4(0xb1357bf9), bytes4(0x12b3b4e6), bytes4(0xad7a672f), bytes4(0xbf2d9e0b), bytes4(0xa44bca8e), bytes4(0xc71367b5), bytes4(0x24f0f548), bytes4(0x6f5e4488), bytes4(0xc78731dc), bytes4(0x386df6eb), bytes4(0xd6356ff4), bytes4(0xab486929), bytes4(0xfae514f8), bytes4(0x2e1a7d4d), bytes4(0x24025b19), bytes4(0x422b1077)
    ];
    bytes4[] selectorsAdmin = [
        bytes4(0x1ee433bf), bytes4(0x8bf34237), bytes4(0xe932b37b), bytes4(0x43a37564), bytes4(0x25dc5807), bytes4(0x4fbbea95), bytes4(0x11ac7c0f), bytes4(0xef9f56cc)
    ];

    function setUp() public {

        // manager = LiquidStakingManager(address(managerProxy));
        // + manager.initialize();

        // distr = NDistributor(address(distrProxy));
        // + distr.initialize();
        // + distr.addUtility("LiquidStaking");

        // nastr = NASTR(address(nastrProxy));
        // + nastr.initialize(address(distr));

        // + distr.grantRole(keccak256("MANAGER_CONTRACT"), address(nastr));

        // ls = LiquidStaking(payable(address(lsProxy)));
        // + ls.initialize(
        //     "nASTR",
        //     "LiquidStaking",
        //     address(distr)
        // );

        // nftdistr = NFTDistributor(address(nftdistrProxy));
        // + nftdistr.initialize(
        //     address(distr),
        //     address(nastr),
        //     address(ls),
        //     address(adistrProxy)
        // );

        // + nastr.setNftDistributor(address(nftdistr));

        // adistr = AdaptersDistributor(address(adistrProxy));
        // + adistr.initialize(address(ls));
        // + adistr.setNftDistributor(address(nftdistr));

        // ls.setLiquidStakingManager(address(manager));

        // lsMain = new LiquidStakingMain();

        // manager.addSelectorsBatch(
        //     selectorsMain,
        //     address(lsMain)
        // );
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // admin = new ProxyAdmin();

        // lsImpl = new LiquidStaking();
        // managerImpl = new LiquidStakingManager();
        // distrImpl = new NDistributor();
        // nastrImpl = new NASTR();
        // nftdistrImpl = new NFTDistributor();
        // adistrImpl = new AdaptersDistributor();

        // lsProxy = new TransparentUpgradeableProxy(address(lsImpl), address(admin), "");
        // managerProxy = new TransparentUpgradeableProxy(address(managerImpl), address(admin), "");
        // distrProxy = new TransparentUpgradeableProxy(address(distrImpl), address(admin), "");
        // nastrProxy = new TransparentUpgradeableProxy(address(nastrImpl), address(admin), "");
        // nftdistrProxy = new TransparentUpgradeableProxy(address(nftdistrImpl), address(admin), "");
        // adistrProxy = new TransparentUpgradeableProxy(address(adistrImpl), address(admin), "");

        // console2.log(address(lsProxy)); // 0x4221A3DB650B568Eb7d53F130E2F8C136fd1e3Fd
        // console2.log(address(managerProxy)); // 0x1908D4c618ACEC1Ee5D510d876244eCa7b4D740c
        // console2.log(address(distrProxy)); // 0x97A232D71FA5F69405D3C48a64a39bC05911EB1A
        // console2.log(address(nastrProxy)); // 0xf03715D3B8974556C2F79871d779Fe355Af83a51
        // console2.log(address(nftdistrProxy)); // 0xAF6335653A791e7e20d4aaDA0879E937283F485C
        // console2.log(address(adistrProxy)); // 0x1bbD44442e09a35798e68B183c198ea8d6456387

        // lsMain = new LiquidStakingMain();
        // lsAdmin = new LiquidStakingAdmin();
        // console2.log(address(lsMain)); //0x54bFE65f4E548C94e4B20087aE437403481089d7
        // console2.log(address(lsAdmin)); //0x4Ec9b2faf884810D8fF4Ff19aC42F438398AAcbA
 
        // manager = LiquidStakingManager(0x1908D4c618ACEC1Ee5D510d876244eCa7b4D740c);
        // manager.addSelectorsBatch(
        //     selectorsMain,
        //     0x54bFE65f4E548C94e4B20087aE437403481089d7
        // );
        // manager.addSelectorsBatch(
        //     selectorsAdmin,
        //     0x4Ec9b2faf884810D8fF4Ff19aC42F438398AAcbA
        // );

        // lsMisc = new LiquidStakingMisc();
        // console2.log(address(lsMisc)); // 0xd1f3CC589f2DC0ceBC6Be2546b973117c842718d

        ls = new LiquidStaking();
        console2.log(address(ls)); //0x4700c6795f8Acb98F397C13812D508780428C476

        vm.stopBroadcast();
    }
}