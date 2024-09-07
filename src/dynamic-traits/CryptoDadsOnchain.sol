// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721CUpgradeable} from "@limitbreak/erc721c/ERC721C.sol";
import {BasicRoyaltiesUpgradeable} from "@limitbreak/programmable-royalties/BasicRoyaltiesUpgradeable.sol";

interface ITraitManager {
    function updateTraits(uint256 tokenId, uint256[] calldata traitIds) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setBaseURI(string calldata newBaseURI) external;
    function removeTrait(uint256 tokenId, uint256 traitId) external;
    function initialTraitsBulk(uint256[] calldata tokenIds, uint256[][] calldata traitIdsList) external;
    function defineTrait(uint256 traitId, bytes32 key, bytes32 value) external;
    function setIncompatibleTraits(uint256 traitId, uint256[] calldata incompatibleTraitIds) external;
    function addExemptKey(string calldata key) external;
    function removeExemptKey(string calldata key) external;
}

contract CryptoDadsOnchain is Initializable, ERC721CUpgradeable, BasicRoyaltiesUpgradeable, OwnableUpgradeable {
    address private _trustedAddress;
    ITraitManager public traitManager;

    function initialize(
        string memory _name,
        string memory _symbol,
        address trustedAddress,
        address traitManagerAddress
    ) public initializer {
        __ERC2981_init();
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        _trustedAddress = trustedAddress;
        traitManager = ITraitManager(traitManagerAddress);

        // Set royalty receiver to the contract creator,
        // at 0% to begin (default denominator is 10000 for future changes).
        _setDefaultRoyalty(msg.sender, 0);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyTrusted() {
        require(msg.sender == _trustedAddress, "Caller is not the trusted address");
        _;
    }

    // Set the trusted address that can initialize/update traits
    function setTrustedAddress(address newTrustedAddress) external onlyOwner {
        _trustedAddress = newTrustedAddress;
    }

    // Set base URI for the metadata stored in TraitManager
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        traitManager.setBaseURI(newBaseURI);
    }

    // Define a new trait and return the traitId
    function defineTrait(uint256 traitId, bytes32 key, bytes32 value) external onlyTrusted {
        traitManager.defineTrait(traitId, key, value);
    }

    // Set incompatible traits for a specific traitId
    function setIncompatibleTraits(uint256 traitId, uint256[] calldata incompatibleTraitIds) external onlyTrusted {
        traitManager.setIncompatibleTraits(traitId, incompatibleTraitIds);
    }

    // Add an exempt key to the trait manager
    function addExemptKey(string calldata key) external onlyTrusted {
        traitManager.addExemptKey(key);
    }

    // Remove an exempt key from the trait manager
    function removeExemptKey(string calldata key) external onlyTrusted {
        traitManager.removeExemptKey(key);
    }

    // Update traits for a specific tokenId using traitIds
    function updateTraits(
        uint256 tokenId,
        uint256[] calldata traitIds
    ) external onlyTrusted {
        traitManager.updateTraits(tokenId, traitIds);
    }

    // Remove a specific trait by traitId for a tokenId
    function removeTrait(uint256 tokenId, uint256 traitId) external onlyTrusted {
        traitManager.removeTrait(tokenId, traitId);
    }

    // Bulk initialize traits for multiple tokenIds using arrays of traitIds
    function initializeTraitsBulk(
        uint256[] calldata tokenIds,
        uint256[][] calldata traitIdsList
    ) external onlyTrusted {
        traitManager.initialTraitsBulk(tokenIds, traitIdsList);
    }

    // Return tokenURI by fetching from TraitManager
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return traitManager.tokenURI(tokenId);
    }

    // Function to airdrop multiple NFTs to different addresses
    function airdrop(address[] calldata _tokenOwners, uint[] calldata _tokenIds) external onlyOwner {
        require(_tokenOwners.length == _tokenIds.length, "CryptoDads: tokenOwners and tokenIds length mismatch");
        for (uint i = 0; i < _tokenOwners.length; i++) {
            _safeMint(_tokenOwners[i], _tokenIds[i]);
        }
    }

    // Function to update the trait manager's contract address
    function setTraitManager(address newTraitManagerAddress) external onlyOwner {
        require(newTraitManagerAddress != address(0), "Invalid TraitManager address");
        traitManager = ITraitManager(newTraitManagerAddress);
    }

    // Function to set default royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // ERC721CUpgradeable and ERC2981Upgradeable support interface override
    function supportsInterface(bytes4 interfaceId) public view override(ERC721CUpgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721CUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }
}
