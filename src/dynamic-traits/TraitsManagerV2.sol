// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TraitsManagerV2 is Initializable {
    using Strings for uint256;

    // Struct for smaller traits with bytes32 key and value
    struct Trait {
        bytes32 key;  // Packed as bytes32 for gas optimization
        bytes32 value; // Packed for traits with short values
    }

    // Struct to store larger "Dad Joke" values
    struct DadJoke {
        string joke;
    }

    // Use uint256 as the traitId directly, mapping traitId to Trait structure
    mapping(uint256 => Trait) private _traitDefinitions;

    // Mapping for Dad Jokes (longer strings, immutable per token)
    mapping(uint256 => DadJoke) private _dadJokes;

    // Mapping of tokenId to an array of traitIDs
    mapping(uint256 => uint256[]) private _tokenTraits;

    // Mapping for token names
    mapping(uint256 => string) private _tokenNames;

    // Mapping for incompatible traits
    mapping(uint256 => uint256[]) private _incompatibleTraits;

    // Exempt keys mapping for non-unique trait combinations
    mapping(bytes32 => bool) private _exemptTraitKeys;

    uint256 public nextTraitId;
    string public baseURI;
    address public nftContract;
    address public moderator;

    // Events
    event BaseURISet(string baseURI);
    event NFTContractSet(address nftContract);
    event TraitsUpdated(uint256 indexed tokenId, uint256[] traitIds);
    event TraitDefined(uint256 traitId, bytes32 key, bytes32 value);
    event DadJokeSet(uint256 indexed tokenId, string joke);
    event IncompatibleTraitSet(uint256 traitId, uint256 incompatibleTraitId);
    event ExemptKeyAdded(bytes32 key);
    event ExemptKeyRemoved(bytes32 key);
    event TokenNameSet(uint256 indexed tokenId, string name);
    event ModeratorSet(address moderator);

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Caller is not the NFT contract");
        _;
    }

    modifier onlyModeratorOrNFTContract() {
        require(msg.sender == moderator || msg.sender == nftContract, "Caller is not the moderator or NFT contract");
        _;
    }

    // Initialize function to replace constructor for upgradeability
    function initialize(address _nftContract, string memory _baseURI, address _moderator) public initializer {
        nftContract = _nftContract;
        baseURI = _baseURI;
        nextTraitId = 1;
        moderator = _moderator;
    }

    // Define a new trait with a specific traitId, key, and short value (both bytes32)
    function defineTrait(uint256 traitId, bytes32 key, bytes32 value) external onlyNFTContract {
        require(traitId > 0, "Trait ID must be greater than 0");
        require(_traitDefinitions[traitId].key == bytes32(0), "Trait ID already exists");

        _traitDefinitions[traitId] = Trait({key: key, value: value});
        emit TraitDefined(traitId, key, value);
    }

    // Set an immutable Dad Joke for a tokenId
    function setDadJoke(uint256 tokenId, string calldata joke) external onlyNFTContract {
        require(bytes(_dadJokes[tokenId].joke).length == 0, "Dad Joke already set"); // Only allow setting once
        _dadJokes[tokenId] = DadJoke(joke);
        emit DadJokeSet(tokenId, joke);
    }

    // Set a name for a specific tokenId (can be called by NFT contract or moderator)
    function setTokenName(uint256 tokenId, string calldata name) external onlyModeratorOrNFTContract {
        _tokenNames[tokenId] = name;
        emit TokenNameSet(tokenId, name);
    }

    // Set the moderator (can be called only by the NFT contract)
    function setModerator(address _moderator) external onlyNFTContract {
        moderator = _moderator;
        emit ModeratorSet(_moderator);
    }

    // Function to add a key to the exempt list
    function addExemptKey(bytes32 key) external onlyNFTContract {
        _exemptTraitKeys[key] = true;
        emit ExemptKeyAdded(key);
    }

    // Function to remove a key from the exempt list
    function removeExemptKey(bytes32 key) external onlyNFTContract {
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

    // Get a Dad Joke for a tokenId
    function getDadJoke(uint256 tokenId) external view returns (string memory) {
        return _dadJokes[tokenId].joke;
    }

    // Update token traits without _tokenTraitKeys
    function updateTraits(uint256 tokenId, uint256[] calldata traitIds) external onlyNFTContract {
        uint256[] storage currentTraits = _tokenTraits[tokenId];

        for (uint256 i = 0; i < traitIds.length; i++) {
            uint256 traitId = traitIds[i];
            bytes32 key = _traitDefinitions[traitId].key;

            bool traitExists = false;
            for (uint256 j = 0; j < currentTraits.length; j++) {
                uint256 currentTraitId = currentTraits[j];

                // If a trait with the same key exists, overwrite it
                if (_traitDefinitions[currentTraitId].key == key) {
                    currentTraits[j] = traitId;
                    traitExists = true;
                    break;
                }
            }

            // If the trait didn't already exist, add it
            if (!traitExists) {
                currentTraits.push(traitId);
            }
        }

        emit TraitsUpdated(tokenId, traitIds);
    }

    // Generate tokenURI, using the token name if set, otherwise fallback to tokenId
    function tokenURI(uint256 tokenId) external view onlyNFTContract returns (string memory) {
        string memory imageURI = string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".png"));

        // Use the name if present, otherwise fallback to tokenId
        string memory tokenName = bytes(_tokenNames[tokenId]).length > 0 ? _tokenNames[tokenId] : tokenId.toString();

        uint256[] memory traitIds = _tokenTraits[tokenId];
        bytes memory attributes;

        for (uint256 i = 0; i < traitIds.length; i++) {
            Trait memory trait = _traitDefinitions[traitIds[i]];
            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "', string(abi.encodePacked(trait.key)), '", "value": "', string(abi.encodePacked(trait.value)), '"},'
            );

        }

        // Add the immutable Dad Joke
        string memory dadJoke = _dadJokes[tokenId].joke;
        attributes = abi.encodePacked(attributes, ',{"trait_type": "Dad Joke", "value": "', dadJoke, '"}');

        bytes memory json = abi.encodePacked(
            '{"name": "', tokenName, '",',
            '"description": "CryptoDads Onchain",',
            '"image": "', imageURI, '",',
            '"attributes": [', attributes, ']}'
        );

        string memory jsonBase64 = Base64.encode(json);
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }
}
