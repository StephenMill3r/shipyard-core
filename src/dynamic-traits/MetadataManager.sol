// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract TraitManager {
    using Strings for uint256;

    struct Trait {
        string key;
        string value;
    }

    // Mapping of tokenId to array of key-value pair traits
    mapping(uint256 => Trait[]) private _tokenTraits;
    string public baseURI;

    address public nftContract;

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
        _;
    }

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    function setNFTContract(address _nftContract) external {
        require(nftContract == address(0), "NFT contract address already set");
        nftContract = _nftContract;
    }

    function initializeTraits(
        uint256 tokenId,
        string[17] calldata keys,
        string[17] calldata values
    ) external onlyNFTContract {
        require(_tokenTraits[tokenId].length == 0, "Traits already initialized");

        for (uint256 i = 0; i < keys.length; i++) {
            _tokenTraits[tokenId].push(Trait(keys[i], values[i]));
        }
    }

    function updateTraits(
        uint256 tokenId,
        string[3] calldata keys,
        string[3] calldata values
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
    }

    function tokenURI(uint256 tokenId) external view onlyNFTContract returns (string memory) {
        Trait[] memory traits = _tokenTraits[tokenId];
        string memory imageURI = string(abi.encodePacked(baseURI, "/", tokenId.toString()));

        bytes memory attributes;
        for (uint256 i = 0; i < traits.length; i++) {
            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "', traits[i].key, '", "value": "', traits[i].value, '"}'
            );
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

    function setBaseURI(string calldata newBaseURI) external onlyNFTContract {
        baseURI = newBaseURI;
    }
}
