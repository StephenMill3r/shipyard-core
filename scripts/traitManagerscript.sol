// DeployCryptoDadsOnchain.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {TraitsManagerV2} from "../src/dynamic-traits/TraitsManagerV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployTraitsManagerScript is Script {
    function run() external {
        address nftContractAddress = 0x80Fae9a481c2D61a5e50B7F9BFef4E27A09D87cd;  // Replace with your NFT contract address
        address moderator = 0xAE9bAA7925a49806308703c37981144A24cC1F76;
        string memory baseURI = "https://cryptodadsnft.nyc3.cdn.digitaloceanspaces.com/cryptodads-images";  // Replace with your base URI

        vm.startBroadcast();

        // Deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // Deploy the logic contract for TraitsManagerV1
        TraitsManagerV2 logic = new TraitsManagerV2();

        // Initialize data for the proxy, which includes calling the TraitsManagerV1 initialize function
        bytes memory data = abi.encodeWithSelector(
            logic.initialize.selector,
            nftContractAddress,  // Address of the NFT contract
            baseURI,              // Base URI for traits metadata
            moderator
        );

        // Deploy TransparentUpgradeableProxy with the logic contract and proxy admin
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(logic),
            address(proxyAdmin),
            data
        );

        vm.stopBroadcast();
    }
}
