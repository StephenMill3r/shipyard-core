// SPDX-License-Identifier: MIT -- MAKE THIS UPGRADEABLE -- THERE WILL BE ISSUES WITH THE CURRENT IMPLEMENTATION
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract TraitManagerV1 {
    using Strings for uint256;

    struct Trait {
        string key;
        string value;
    }

    // Mapping of tokenId to array of key-value pair traits
    mapping(uint256 => Trait[]) private _tokenTraits;
    string public baseURI;

    address public nftContract;

    // Events
    event BaseURISet(string baseURI);
    event NFTContractSet(address nftContract);
    event TraitsUpdated(uint256 indexed tokenId, string[] keys, string[] values);
    event TraitRemoved(uint256 indexed tokenId, string key);
    event InitializeTraits(uint256[] tokenIds, string key, string[] values);

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
        _;
    }

    // Function to set the baseURI, callable by the NFT contract
    function setBaseURI(string memory _baseURI) external onlyNFTContract {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function setNFTContract(address _nftContract) external {
        require(nftContract == address(0), "NFT contract address already set");
        nftContract = _nftContract;
        emit NFTContractSet(_nftContract);
    }

    function updateTraits(
        uint256 tokenId,
        string[] calldata keys,
        string[] calldata values
    ) external onlyNFTContract {
        Trait[] storage traits = _tokenTraits[tokenId];

        for (uint256 i = 0; i < keys.length; i++) {
            if (bytes(keys[i]).length == 0) continue; // Skip empty keys

            bool updated = false;

            for (uint256 j = 0; j < traits.length; j++) {
                if (keccak256(bytes(traits[j].key)) == keccak256(bytes(keys[i]))) {
                    traits[j].value = values[i];
                    updated = true;
                    break;
                }
            }

            if (!updated) {
                traits.push(Trait(keys[i], values[i]));
            }
        }

        emit TraitsUpdated(tokenId, keys, values);
    }

    // New function to remove a trait by its key
    function removeTrait(uint256 tokenId, string calldata key) external onlyNFTContract {
        Trait[] storage traits = _tokenTraits[tokenId];
        for (uint256 i = 0; i < traits.length; i++) {
            if (keccak256(bytes(traits[i].key)) == keccak256(bytes(key))) {
                traits[i] = traits[traits.length - 1]; // Move last element to the deleted spot
                traits.pop(); // Remove the last element
                emit TraitRemoved(tokenId, key);
                break;
            }
        }
    }

    // Function to get the key-value pairs for a single or multiple tokenIDs
    function getTraits(uint256[] calldata tokenIds) external view returns (Trait[][] memory) {
        Trait[][] memory allTraits = new Trait[][](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            allTraits[i] = _tokenTraits[tokenIds[i]];
        }

        return allTraits;
    }

    // Batch apply traits function for multiple tokenIds
    function InitialTraitsBulk(
        uint256[] calldata tokenIds,
        string calldata key,
        string[] calldata values
    ) external onlyNFTContract {
        require(tokenIds.length == values.length, "TokenIDs and values length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Trait[] storage traits = _tokenTraits[tokenIds[i]];
            bool updated = false;

            // Update existing key-value if the key exists
            for (uint256 j = 0; j < traits.length; j++) {
                if (keccak256(bytes(traits[j].key)) == keccak256(bytes(key))) {
                    traits[j].value = values[i];
                    updated = true;
                    break;
                }
            }

            // If the key does not exist, add a new trait
            if (!updated) {
                traits.push(Trait(key, values[i]));
            }
        }

        emit InitializeTraits(tokenIds, key, values);
    }

    function tokenURI(uint256 tokenId) external view onlyNFTContract returns (string memory) {
        Trait[] memory traits = _tokenTraits[tokenId];
        string memory imageURI = string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".png"));

        bytes memory attributes;
        for (uint256 i = 0; i < traits.length; i++) {
            // Skip attributes with empty value
            if (bytes(traits[i].value).length == 0) {
                continue;
            }

            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "', traits[i].key, '", "value": "', traits[i].value, '"}'
            );

            // Only add a comma if this is not the last trait
            if (i < traits.length - 1) {
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
