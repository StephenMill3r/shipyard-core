// DeployCryptoDadsOnchainV2.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CryptoDadsOnchain} from "../src/dynamic-traits/CryptoDadsOnchain.sol";

contract DeployCryptoDadsOnchain is Script {
    function run() external {
        address proxyAdminAddress = 0xAbdd73800f7dA00Ade4f9DB0Ad0Ed7cCFaA664Ed;  // ProxyAdmin address
        address proxyAddress = 0x3ce8f7c7302D6e4273B579afD3A3788E57758139;  // Proxy address

        vm.startBroadcast();
        
        // Step 1: Deploy the new implementation
        CryptoDadsOnchain newImplementation = new CryptoDadsOnchain();
        
        // Step 2: Upgrade the proxy to point to the new implementation
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);

        // Call the upgrade function on ProxyAdmin
        proxyAdmin.upgrade(proxyAddress, address(newImplementation));  // Just pass the address of the proxy and new implementation

        vm.stopBroadcast();
    }
}
