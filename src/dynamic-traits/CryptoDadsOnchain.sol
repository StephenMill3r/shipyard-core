// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721CUpgradeable} from "@limitbreak/erc721c/ERC721C.sol";
import {BasicRoyaltiesUpgradeable} from "@limitbreak/programmable-royalties/BasicRoyaltiesUpgradeable.sol";

interface ITraitManager {
    function updateTraits(uint256 tokenId, string[] calldata keys, string[] calldata values) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setBaseURI(string calldata newBaseURI) external;
    function removeTrait(uint256 tokenId, string calldata key) external;
    function InitialTraitsBulk(uint256[] calldata tokenIds, string calldata key, string[] calldata values) external;
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

    // Update traits for a specific tokenId
    function updateTraits(
        uint256 tokenId,
        string[] calldata keys,
        string[] calldata values
    ) external onlyTrusted {
        traitManager.updateTraits(tokenId, keys, values);
    }

    // Remove a specific trait by key for a tokenId
    function removeTrait(uint256 tokenId, string calldata key) external onlyTrusted {
        traitManager.removeTrait(tokenId, key);
    }

    // Bulk initialize traits for multiple tokenIds
    function initializeTraitsBulk(
        uint256[] calldata tokenIds,
        string calldata key,
        string[] calldata values
    ) external onlyTrusted {
        traitManager.InitialTraitsBulk(tokenIds, key, values);
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
