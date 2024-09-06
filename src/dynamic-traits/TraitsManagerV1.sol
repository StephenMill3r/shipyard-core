// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TraitsManagerV1 is Initializable {
    using Strings for uint256;

    // Structure to store trait key and value
    struct Trait {
        string key;
        string value;
    }

    // Global mapping of traitID to Trait (key-value pair)
    mapping(uint256 => Trait) private _traitDefinitions;

    // Mapping of tokenId to an array of traitIDs
    mapping(uint256 => uint256[]) private _tokenTraits;

    // Mapping of tokenId to the trait key assigned to the token
    mapping(uint256 => mapping(string => uint256)) private _tokenTraitKeys;

    // Incompatible traits mapping: traitID => incompatible traitID[]
    mapping(uint256 => uint256[]) private _incompatibleTraits;

    // To track unique traitID combinations
    mapping(bytes32 => bool) private _uniqueTraitSet;

    // Mapping for exempt trait keys
    mapping(string => bool) private _exemptTraitKeys;

    uint256 public nextTraitId;
    string public baseURI;
    address public nftContract;

    // Events
    event BaseURISet(string baseURI);
    event NFTContractSet(address nftContract);
    event TraitsUpdated(uint256 indexed tokenId, uint256[] traitIds);
    event TraitRemoved(uint256 indexed tokenId, uint256 traitId);
    event TraitDefined(uint256 traitId, string key, string value);
    event IncompatibleTraitSet(uint256 traitId, uint256 incompatibleTraitId);
    event ExemptKeyAdded(string key);
    event ExemptKeyRemoved(string key);

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
        _;
    }

    // Initialize function to replace constructor for upgradeability
    function initialize(address _nftContract, string memory _baseURI) public initializer {
        nftContract = _nftContract;
        baseURI = _baseURI;
        nextTraitId = 1; // Start trait IDs at 1
    }

    // Define a new trait with a key and value, returns the traitId
    function defineTrait(string calldata key, string calldata value) external onlyNFTContract returns (uint256) {
        _traitDefinitions[nextTraitId] = Trait({key: key, value: value});
        emit TraitDefined(nextTraitId, key, value);
        nextTraitId++;
        return nextTraitId - 1;
    }

    function bulkDefineTraits(string[] calldata keys, string[] calldata values) external onlyNFTContract {
        require(keys.length == values.length, "Keys and values length mismatch");

        for (uint256 i = 0; i < keys.length; i++) {
            _traitDefinitions[nextTraitId] = Trait({key: keys[i], value: values[i]});
            emit TraitDefined(nextTraitId, keys[i], values[i]);
            nextTraitId++;
        }
    }

    // Function to add a key to the exempt list
    function addExemptKey(string memory key) external onlyNFTContract {
        _exemptTraitKeys[key] = true;
        emit ExemptKeyAdded(key);
    }

    // Function to remove a key from the exempt list
    function removeExemptKey(string memory key) external onlyNFTContract {
        _exemptTraitKeys[key] = false;
        emit ExemptKeyRemoved(key);
    }

    // Set incompatible traits for a specific traitID
    function setIncompatibleTraits(uint256 traitId, uint256[] calldata incompatibleTraitIds) external onlyNFTContract {
        _incompatibleTraits[traitId] = incompatibleTraitIds;

        for (uint256 i = 0; i < incompatibleTraitIds.length; i++) {
            emit IncompatibleTraitSet(traitId, incompatibleTraitIds[i]);
        }
    }

    // Function to set the baseURI, callable by the NFT contract
    function setBaseURI(string memory _baseURI) external onlyNFTContract {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    // Function to set the NFT contract address, callable once
    function setNFTContract(address _nftContract) external {
        require(nftContract == address(0), "NFT contract address already set");
        nftContract = _nftContract;
        emit NFTContractSet(_nftContract);
    }

    // Helper functions for troubleshooting

    // Get trait details for a given traitId
    function getTraitDefinition(uint256 traitId) external view returns (string memory key, string memory value) {
        Trait memory trait = _traitDefinitions[traitId];
        return (trait.key, trait.value);
    }

    // Get all traitIds associated with a specific tokenId
    function getTokenTraits(uint256 tokenId) external view returns (uint256[] memory) {
        return _tokenTraits[tokenId];
    }

    // Get traitId associated with a specific key for a given tokenId
    function getTokenTraitByKey(uint256 tokenId, string calldata key) external view returns (uint256) {
        return _tokenTraitKeys[tokenId][key];
    }

    // Get incompatible traits for a specific traitId
    function getIncompatibleTraits(uint256 traitId) external view returns (uint256[] memory) {
        return _incompatibleTraits[traitId];
    }

    // Check if a key is exempt from the uniqueness check
    function isExemptKey(string calldata key) external view returns (bool) {
        return _exemptTraitKeys[key];
    }

    // Check if a specific combination of traitIds is unique
    function isUniqueTraitSet(uint256[] calldata traitIds) external view returns (bool) {
        bytes32 traitHash;
        for (uint256 i = 0; i < traitIds.length; i++) {
            string memory key = _traitDefinitions[traitIds[i]].key;
            if (!_exemptTraitKeys[key]) {
                traitHash = keccak256(abi.encode(traitHash, traitIds[i]));
            }
        }
        return !_uniqueTraitSet[traitHash];
    }

    // Get the baseURI for the contract
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    // Get the NFT contract address
    function getNFTContract() external view returns (address) {
        return nftContract;
    }

    // Update traits for a specific tokenId by assigning traitIDs
    function updateTraits(uint256 tokenId, uint256[] calldata traitIds) external onlyNFTContract {
        // Collect current traitIds not being updated (keys other than those in traitIds)
        uint256[] memory existingTraitIds = _getCurrentTraitIdsExcludingUpdated(tokenId, traitIds);

        // Combine existing and new traitIds
        uint256[] memory combinedTraitIds = _combineTraitIds(existingTraitIds, traitIds);

        // Ensure the new set of traitIDs (including the existing ones) is unique
        require(_isUniqueTraitSet(combinedTraitIds), "Trait set is not unique");

        for (uint256 i = 0; i < traitIds.length; i++) {
            uint256 traitId = traitIds[i];
            Trait memory trait = _traitDefinitions[traitId];

            // Check if the trait is incompatible with any existing traits for the token, excluding the same key
            require(!_hasIncompatibleTraits(tokenId, traitId, trait.key), "Incompatible traits detected");

            // If a trait with the same key already exists, overwrite it
            if (_tokenTraitKeys[tokenId][trait.key] != 0) {
                _removeTraitByKey(tokenId, trait.key);
            }

            // Update the trait key mapping for this tokenId
            _tokenTraitKeys[tokenId][trait.key] = traitId;

            // Add the traitId to the token's traits array
            _tokenTraits[tokenId].push(traitId);
        }

        // Register the new combined trait set as used
        _registerUniqueTraitSet(combinedTraitIds);

        emit TraitsUpdated(tokenId, traitIds);
    }

    // Helper function to get current traitIds excluding those with the same keys being updated
    function _getCurrentTraitIdsExcludingUpdated(uint256 tokenId, uint256[] memory newTraitIds) internal view returns (uint256[] memory) {
        uint256 totalTraits = _tokenTraits[tokenId].length;
        uint256[] memory existingTraitIds = new uint256[](totalTraits);
        uint256 count = 0;

        for (uint256 i = 0; i < totalTraits; i++) {
            uint256 existingTraitId = _tokenTraits[tokenId][i];
            string memory existingKey = _traitDefinitions[existingTraitId].key;

            bool isBeingUpdated = false;

            // Check if the key is being updated
            for (uint256 j = 0; j < newTraitIds.length; j++) {
                if (keccak256(bytes(_traitDefinitions[newTraitIds[j]].key)) == keccak256(bytes(existingKey))) {
                    isBeingUpdated = true;
                    break;
                }
            }

            // If the key is not being updated, include the traitId
            if (!isBeingUpdated) {
                existingTraitIds[count] = existingTraitId;
                count++;
            }
        }

        // Resize the array to remove empty slots
        assembly {
            mstore(existingTraitIds, count)
        }

        return existingTraitIds;
    }

    // Combine existing and new traitIds into one array
    function _combineTraitIds(uint256[] memory existingTraitIds, uint256[] memory newTraitIds) internal pure returns (uint256[] memory) {
        uint256 combinedLength = existingTraitIds.length + newTraitIds.length;
        uint256[] memory combinedTraitIds = new uint256[](combinedLength);

        for (uint256 i = 0; i < existingTraitIds.length; i++) {
            combinedTraitIds[i] = existingTraitIds[i];
        }

        for (uint256 j = 0; j < newTraitIds.length; j++) {
            combinedTraitIds[existingTraitIds.length + j] = newTraitIds[j];
        }

        return combinedTraitIds;
    }

    // Check if the trait set is unique by hashing the traitIds and looking it up in _uniqueTraitSet, skipping exempt keys
    function _isUniqueTraitSet(uint256[] memory traitIds) internal view returns (bool) {
        bytes32 traitHash;

        // Filter out exempt trait keys from the uniqueness check
        for (uint256 i = 0; i < traitIds.length; i++) {
            string memory key = _traitDefinitions[traitIds[i]].key;
            if (!_exemptTraitKeys[key]) {  // Only include non-exempt keys in the hash
                traitHash = keccak256(abi.encode(traitHash, traitIds[i]));
            }
        }

        return !_uniqueTraitSet[traitHash]; // If it exists, it's not unique
    }

    // Register the trait set in the _uniqueTraitSet mapping
    function _registerUniqueTraitSet(uint256[] memory traitIds) internal {
        bytes32 traitHash = keccak256(abi.encode(traitIds));
        _uniqueTraitSet[traitHash] = true; // Mark this combination as used
    }

    // Remove a specific trait by key for a tokenId
    function _removeTraitByKey(uint256 tokenId, string memory key) internal {
        uint256 traitId = _tokenTraitKeys[tokenId][key];
        if (traitId == 0) return;

        uint256[] storage traits = _tokenTraits[tokenId];

        // Remove the traitId from _tokenTraits
        for (uint256 i = 0; i < traits.length; i++) {
            if (traits[i] == traitId) {
                traits[i] = traits[traits.length - 1]; // Replace with the last element
                traits.pop(); // Remove the last element
                break;
            }
        }

        // Remove the trait from _tokenTraitKeys
        delete _tokenTraitKeys[tokenId][key];

        emit TraitRemoved(tokenId, traitId);
    }

    // Check if a token has incompatible traits, excluding traits with the same key
    function _hasIncompatibleTraits(uint256 tokenId, uint256 traitId, string memory key) internal view returns (bool) {
        uint256[] memory tokenTraitIds = _tokenTraits[tokenId];
        uint256[] memory incompatibleTraitIds = _incompatibleTraits[traitId];

        for (uint256 i = 0; i < tokenTraitIds.length; i++) {
            uint256 existingTraitId = tokenTraitIds[i];

            // Exclude traits with the same key from the incompatible check
            if (keccak256(bytes(_traitDefinitions[existingTraitId].key)) == keccak256(bytes(key))) {
                continue;
            }

            // Check if the current trait is incompatible with the existing ones
            for (uint256 j = 0; j < incompatibleTraitIds.length; j++) {
                if (existingTraitId == incompatibleTraitIds[j]) {
                    return true;
                }
            }
        }

        return false;
    }

    // Get the traits for a specific tokenId
    function getTraits(uint256 tokenId) external view returns (string[] memory keys, string[] memory values) {
        uint256[] memory traitIds = _tokenTraits[tokenId];
        keys = new string[](traitIds.length);
        values = new string[](traitIds.length);

        for (uint256 i = 0; i < traitIds.length; i++) {
            Trait memory trait = _traitDefinitions[traitIds[i]];
            keys[i] = trait.key;
            values[i] = trait.value;
        }

        return (keys, values);
    }

    // Batch apply traits function for multiple tokenIds
    function initialTraitsBulk(uint256[] calldata tokenIds, uint256[] calldata traitIds) external onlyNFTContract {
        require(tokenIds.length == traitIds.length, "TokenIDs and traitIDs length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 traitId = traitIds[i];
            Trait memory trait = _traitDefinitions[traitId];

            // Check for incompatibilities, excluding the same key
            require(!_hasIncompatibleTraits(tokenIds[i], traitId, trait.key), "Incompatible traits detected");

            // Overwrite the trait if the key already exists
            if (_tokenTraitKeys[tokenIds[i]][trait.key] != 0) {
                _removeTraitByKey(tokenIds[i], trait.key);
            }

            _tokenTraits[tokenIds[i]].push(traitId);
            _tokenTraitKeys[tokenIds[i]][trait.key] = traitId;
        }

        emit TraitsUpdated(tokenIds[0], traitIds); // Emit event for the first tokenId as an example
    }

    // Generate tokenURI by combining baseURI and token-specific traits
    function tokenURI(uint256 tokenId) external view onlyNFTContract returns (string memory) {
        string memory imageURI = string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".png"));

        uint256[] memory traitIds = _tokenTraits[tokenId];
        bytes memory attributes;

        for (uint256 i = 0; i < traitIds.length; i++) {
            Trait memory trait = _traitDefinitions[traitIds[i]];
            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "', trait.key, '", "value": "', trait.value, '"}'
            );

            if (i < traitIds.length - 1) {
                attributes = abi.encodePacked(attributes, ',');
            }
        }

        bytes memory json = abi.encodePacked(
            '{"name": "CryptoDad #', tokenId.toString(), '",',
            '"description": "An NFT with dynamic traits.",',
            '"image": "', imageURI, '",',
            '"attributes": [', attributes, ']}'
        );

        string memory jsonBase64 = Base64.encode(json);
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }
}
