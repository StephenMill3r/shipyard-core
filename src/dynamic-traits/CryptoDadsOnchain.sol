// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721CUpgradeable} from "@limitbreak/erc721c/ERC721C.sol";
import {BasicRoyaltiesUpgradeable} from "@limitbreak/programmable-royalties/BasicRoyaltiesUpgradeable.sol";

interface ITraitManager {
    function initializeTraits(uint256 tokenId, string[17] calldata keys, string[17] calldata values) external;
    function updateTraits(uint256 tokenId, string[3] calldata keys, string[3] calldata values) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setBaseURI(string calldata newBaseURI) external;
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

    function setTrustedAddress(address newTrustedAddress) external onlyOwner {
        _trustedAddress = newTrustedAddress;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        traitManager.setBaseURI(newBaseURI);
    }

    function initializeTraits(
        uint256 tokenId, 
        string[17] calldata keys, 
        string[17] calldata values
    ) external onlyTrusted {
        traitManager.initializeTraits(tokenId, keys, values);
    }

    function updateTraits(
        uint256 tokenId, 
        string[3] calldata keys, 
        string[3] calldata values
    ) external onlyTrusted {
        traitManager.updateTraits(tokenId, keys, values);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return traitManager.tokenURI(tokenId);
    }

    function airdrop(address[] calldata _tokenOwners, uint[] calldata _tokenIds) external onlyOwner {
        require(_tokenOwners.length == _tokenIds.length, "CryptoDads: tokenOwners and tokenIds length mismatch");
        for (uint i = 0; i < _tokenOwners.length; i++) {
            _safeMint(_tokenOwners[i], _tokenIds[i]); // this emits a Transfer event during the _mint function call
        }
    }

    function setTraitManager(address newTraitManagerAddress) external onlyOwner {
        require(newTraitManagerAddress != address(0), "Invalid TraitManager address");
        traitManager = ITraitManager(newTraitManagerAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721CUpgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721CUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }
}
