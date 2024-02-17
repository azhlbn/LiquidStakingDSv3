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

contract SingleContractDeployer is Script {
    LiquidStakingAdmin deployedContract;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployedContract = new LiquidStakingAdmin();
        console2.log("Contract address:", address(deployedContract));

        vm.stopBroadcast();
    }
}

// LiquidStaking implementation: 0x34986767952b862862e57b3936282B8e49415065
// LiquidStakingMain 0x5df4DeACdC25741a9dbc330b110F5D2F399809a4
// LiquidStakingAdmin 0x2dE8b68BF7965a865059b53B3f6AdfBEEEDEf098

// LiquidStakingMain
// ["0x06040618","0x973628f6","0xfae514f8","0x59b40f41","0xa217fddf","0x40bf8a8d","0x5f1554e3","0x1b2df850","0x4421bd1e","0x86b3cd26","0x59601ebc","0xa2ce0f4a","0xe2e836f8","0x0c48b5aa","0x54b057f9","0x1f19014b","0xd1058e59","0x00179fbd","0x973628f6","0x06040618","0xdcf425df","0xda3bc958","0x2a14d8f4","0x6bbea766","0x05e2a217","0xc21a7276","0xeb51a44c","0x1dc00785","0xf128f631","0x2ea31bf6","0xc4e137e7","0x248a9ca3","0x2f2ff15d","0x91d14854","0x6f68f2e9","0xc8902a21","0x6f240d2b","0xd00be1e1","0x0f24ca7d","0x8c0f9aac","0x6f1e8533","0x2e4a4a17","0xadc1b956","0xe77ee345","0x12a12a06","0x5495ec81","0xd0b06f5d","0x5ca5914e","0xe09c1954","0x1bb5e2dc","0x078aebd5","0xf1887684","0xbd1bbd3b","0xf692c21d","0xa5ae02ac","0xc3b49d04","0x4d617451","0x5c975abb","0xea4a1104","0xb8d7cac9","0x36568abe","0xd547741f","0x66666aa9","0xa22eae1b","0xfd5e6dd1","0x16934fc4","0xaf66c36b","0x01ffc9a7","0xb1357bf9","0x12b3b4e6","0x525662e3","0xad7a672f","0xbf2d9e0b","0xa44bca8e","0xc71367b5","0x24f0f548","0x6f5e4488","0x600b248f","0xc78731dc","0x386df6eb","0xcb2ec1c0","0xab486929","0xfae514f8","0x2e1a7d4d","0x24025b19","0x82a8d4ec"]
// LiquidStakingStorage ["0x06040618","0x973628f6","0xfae514f8"]

// LiquidStakingAdmin
// ["0x1ee433bf","0xe932b37b","0x27917d60","0xf16ca2e4","0x0f80b592","0x43352d61","0x331d437b","0xc6ecccb8","0x591ffad9","0x14ed1db0","0x43a37564","0xeb4af045","0x19f3f52e","0x11ac7c0f","0xef9f56cc","0x0ceff204"]