// DeployCryptoDadsOnchain.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {CryptoDadsOnchain} from "../src/dynamic-traits/CryptoDadsOnchain.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployCryptoDadsOnchain is Script {
    function run() external {
        address trustedAddress = 0xAE9bAA7925a49806308703c37981144A24cC1F76;  // Replace with your trusted address
        address traitManagerAddress = 0xf27E293649fd70d632C851Ed680298F07c63B991; // Replace with trait manager address

        vm.startBroadcast();

        // Deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // Deploy the logic contract
        CryptoDadsOnchain logic = new CryptoDadsOnchain();

        // Initialize data for the proxy
        bytes memory data = abi.encodeWithSelector(
            logic.initialize.selector,
            "CryptoDads", // _name
            "CDAD",       // _symbol
            trustedAddress,
            traitManagerAddress
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
