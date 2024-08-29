// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721CUpgradeable} from "../limitbreak/erc721c/ERC721C.sol";
import {BasicRoyaltiesUpgradeable} from "../limitbreak/programmable-royalties/BasicRoyaltiesUpgradeable.sol";

/** 
@title CryptoMomsUpgradeable
@author StephenMiller
*/

// LZAppUpgradeable contains ownableUpgradeable as well.
contract CryptoMomsUpgradeable is Initializable, ERC721CUpgradeable, BasicRoyaltiesUpgradeable, OwnableUpgradeable {
    string public baseURI;

    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC2981_init();
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        // Set royalty receiver to the contract creator,
        // at 0% to begin (default denominator is 10000 for future changes).
        _setDefaultRoyalty(msg.sender, 0);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice is an onlyOwner function to mint tokens to those that were part of the snapshot
     * @param _tokenOwners the addresses of the token owners
     * @param _tokenIds a parallel list of tokenIds to mint
     */
    function airdrop(address[] calldata _tokenOwners, uint[] calldata _tokenIds) external onlyOwner {
        require(_tokenOwners.length == _tokenIds.length, "CryptoMoms: tokenOwners and tokenIds length mismatch");
        for (uint i = 0; i < _tokenOwners.length; i++) {
            _safeMint(_tokenOwners[i], _tokenIds[i]); // this emits a Transfer event during the _mint function call
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, so overriding here
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice function to set the base URI for the tokenURI
     * @param newBaseURI the new base URI to set
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721CUpgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721CUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice function to set ERC2981 royalties required by marketplaces
     * @param receiver the address to receive the royalties
     * @param feeNumerator the royalty percentage in basis points of 10000 (7.5% = 750)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }
}
