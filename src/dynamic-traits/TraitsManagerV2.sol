// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TraitsManagerV2 is Initializable {
    using Strings for uint256;

    // Struct for smaller traits with bytes32 key and value
    struct Trait {
        bytes32 key;  // Packed as bytes32 for gas optimization
        bytes32 value; // Packed for traits with short values
    }

    // Use uint256 as the traitId directly, mapping traitId to Trait structure
    mapping(uint256 => Trait) private _traitDefinitions;

    // Mapping for storing the address where dad jokes are stored in SSTORE2
    mapping(uint256 => address) private _dadJokes;

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
    event DadJokeStored(uint256 indexed tokenId, address storageAddress);
    event IncompatibleTraitSet(uint256 traitId, uint256 incompatibleTraitId);
    event ExemptKeyAdded(bytes32 key);
    event ExemptKeyRemoved(bytes32 key);
    event TokenNameSet(uint256 indexed tokenId, string name);
    event ModeratorSet(address moderator);
    event NFTContractUpdated(address oldContract, address newContract);

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

    // New function to update the NFT contract address
    function updateNFTContract(address _newNFTContract) external onlyModeratorOrNFTContract {
        require(_newNFTContract != address(0), "New NFT contract cannot be the zero address");
        address oldContract = nftContract;
        nftContract = _newNFTContract;
        emit NFTContractUpdated(oldContract, _newNFTContract);
    }

    // Function to store dad jokes in a batch using SSTORE2
    function setDadJokesBatch(uint256[] calldata tokenIds, string[] calldata jokes) external onlyNFTContract {
        require(tokenIds.length == jokes.length, "TokenIds and jokes length mismatch");

        bytes memory concatenatedJokes;

        for (uint256 i = 0; i < jokes.length; i++) {
            concatenatedJokes = abi.encodePacked(concatenatedJokes, jokes[i], "|"); // Using "|" as a delimiter
        }

        // Store concatenated jokes in one batch using SSTORE2
        address storageAddress = SSTORE2.write(concatenatedJokes);

        // Assign storage address to all tokenIds in the batch
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _dadJokes[tokenIds[i]] = storageAddress;
        }

        emit DadJokeStored(tokenIds[0], storageAddress); // Emit event for the first token in the batch
    }

    // Function to retrieve a dad joke for a specific tokenId
    function getDadJoke(uint256 tokenId) external view returns (string memory) {
        require(_dadJokes[tokenId] != address(0), "No dad joke stored for this tokenId");

        // Read the concatenated jokes from SSTORE2
        bytes memory concatenatedJokes = SSTORE2.read(_dadJokes[tokenId]);

        // Split the concatenated jokes based on the delimiter "|"
        string[] memory jokes = splitJokes(concatenatedJokes, "|");

        // Find the corresponding joke for the tokenId (assuming sequential tokenIds starting from 1)
        uint256 index = tokenId - 1;
        require(index < jokes.length, "Invalid tokenId");
        return jokes[index];
    }

    // Helper function to split concatenated jokes by a delimiter
    function splitJokes(bytes memory data, string memory delimiter) internal pure returns (string[] memory) {
        uint256 count = 1;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == bytes(delimiter)[0]) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        bytes memory buffer;
        uint256 index = 0;

        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == bytes(delimiter)[0]) {
                result[index] = string(buffer);
                buffer = "";
                index++;
            } else {
                buffer = abi.encodePacked(buffer, data[i]);
            }
        }

        result[index] = string(buffer); // Add the final joke
        return result;
    }

    // Define a new trait with a specific traitId, key, and short value (both bytes32)
    function defineTrait(uint256 traitId, bytes32 key, bytes32 value) external onlyNFTContract {
        require(traitId > 0, "Trait ID must be greater than 0");
        require(_traitDefinitions[traitId].key == bytes32(0), "Trait ID already exists");

        _traitDefinitions[traitId] = Trait({key: key, value: value});
        emit TraitDefined(traitId, key, value);
    }

    // Initialize traits in bulk for multiple tokenIds with multiple traits per tokenId
    function initializeTraitsBulk(uint256[] calldata tokenIds, uint256[][] calldata traitIdsList) external onlyModeratorOrNFTContract {
        require(tokenIds.length == traitIdsList.length, "Length mismatch between tokenIds and traitIds");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256[] calldata traitIds = traitIdsList[i];

            // Directly assign the trait array, replacing dynamic `push()`
            _tokenTraits[tokenId] = traitIds;

            emit TraitsUpdated(tokenId, traitIds);
        }
    }

    // Function to generate the token URI, including the stored dad joke
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
                '{"trait_type": "', bytes32ToString(trait.key), '", "value": "', bytes32ToString(trait.value), '"},');
        }

        // Add the stored Dad Joke
        string memory dadJoke = getDadJoke(tokenId);
        attributes = abi.encodePacked(attributes, '{"trait_type": "Dad Joke", "value": "', dadJoke, '"}');

        bytes memory json = abi.encodePacked(
            '{"name": "', tokenName, '",',
            '"description": "CryptoDads Onchain",',
            '"image": "', imageURI, '",',
            '"attributes": [', attributes, ']}'
        );

        string memory jsonBase64 = Base64.encode(json);
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    // Helper function to convert bytes32 to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = _bytes32[j];
        }
        return string(bytesArray);
    }
}
