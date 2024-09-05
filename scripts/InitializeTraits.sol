// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/CryptoDadsOnchain.sol";  // Update with the path to your contract

contract InitializeTraits is Script {
    CryptoDadsOnchain public contractInstance;

    // Address of your deployed contract
    address public contractAddress = 0xYourDeployedContractAddress;

    struct TraitData {
        uint256 tokenId;
        string[17] keys;
        string[17] values;
    }

    // Function to load JSON data (assuming you provide it as JSON)
    function loadTraitsData(string memory filePath) internal returns (TraitData[] memory) {
        // Example of reading JSON data (you would preprocess the data in a JSON format from Python)
        string memory traitsJson = vm.readFile(filePath);
        bytes memory jsonBytes = bytes(traitsJson);

        // Decode the JSON (assuming correct format)
        TraitData[] memory traitsData = abi.decode(jsonBytes, (TraitData[]));
        return traitsData;
    }

    function run() external {
        vm.startBroadcast(); // Begin broadcasting transactions

        // Load the contract instance
        contractInstance = CryptoDadsOnchain(contractAddress);

        // Load trait data from JSON file (this file should be the output of your Python script)
        TraitData[] memory traits = loadTraitsData("parsed_traits.json");

        // Loop through the parsed traits and initialize for each token
        for (uint256 i = 0; i < traits.length; i++) {
            contractInstance.initializeTraits(
                traits[i].tokenId, 
                traits[i].keys, 
                traits[i].values
            );
        }

        vm.stopBroadcast(); // End broadcasting transactions
    }
}
