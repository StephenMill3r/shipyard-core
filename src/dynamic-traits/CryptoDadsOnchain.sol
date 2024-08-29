// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721CUpgradeable} from "../limitbreak/erc721c/ERC721C.sol";
import {BasicRoyaltiesUpgradeable} from "../limitbreak/programmable-royalties/BasicRoyaltiesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
@title CryptoDadsOnchain with Dynamic Onchain Metadata 
@author 
*/

contract CryptoDadsOnchain is Initializable, ERC721CUpgradeable, BasicRoyaltiesUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    string public baseURI;

    struct MetaDataStruct {
        string eyes;
        string eyewear;
        string hair_style;
        string hair_color;
        string hat;
        string holding;
        string shirt;
        string dad_joke;
        string facial_hair;
        string mouth;
        string skin;
        string dads_top_picks;
        string accessory;
        string neck;
        string jewelry;
        string vibes;
    }

    mapping(uint256 => MetaDataStruct) private _metadata;
    address private _trustedAddress;

    function initialize(string memory _name, string memory _symbol, address trustedAddress) public initializer {
        __ERC2981_init();
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        _trustedAddress = trustedAddress;

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
        baseURI = newBaseURI;
    }

    function updateTraits(
        uint256 tokenId,
        string calldata newEyes,
        string calldata newEyewear,
        string calldata newHairStyle,
        string calldata newHairColor,
        string calldata newHat,
        string calldata newHolding,
        string calldata newShirt,
        string calldata newDadJoke,
        string calldata newFacialHair,
        string calldata newMouth,
        string calldata newSkin,
        string calldata newDadsTopPicks,
        string calldata newAccessory,
        string calldata newNeck,
        string calldata newJewelry,
        string calldata newVibes
    ) external onlyTrusted {
        MetaDataStruct storage metadata = _metadata[tokenId];

        if (keccak256(bytes(newEyes)) != keccak256(bytes("0"))) {
            metadata.eyes = newEyes;
        }
        if (keccak256(bytes(newEyewear)) != keccak256(bytes("0"))) {
            metadata.eyewear = newEyewear;
        }
        if (keccak256(bytes(newHairStyle)) != keccak256(bytes("0"))) {
            metadata.hair_style = newHairStyle;
        }
        if (keccak256(bytes(newHairColor)) != keccak256(bytes("0"))) {
            metadata.hair_color = newHairColor;
        }
        if (keccak256(bytes(newHat)) != keccak256(bytes("0"))) {
            metadata.hat = newHat;
        }
        if (keccak256(bytes(newHolding)) != keccak256(bytes("0"))) {
            metadata.holding = newHolding;
        }
        if (keccak256(bytes(newShirt)) != keccak256(bytes("0"))) {
            metadata.shirt = newShirt;
        }
        if (keccak256(bytes(newDadJoke)) != keccak256(bytes("0"))) {
            metadata.dad_joke = newDadJoke;
        }
        if (keccak256(bytes(newFacialHair)) != keccak256(bytes("0"))) {
            metadata.facial_hair = newFacialHair;
        }
        if (keccak256(bytes(newMouth)) != keccak256(bytes("0"))) {
            metadata.mouth = newMouth;
        }
        if (keccak256(bytes(newSkin)) != keccak256(bytes("0"))) {
            metadata.skin = newSkin;
        }
        if (keccak256(bytes(newDadsTopPicks)) != keccak256(bytes("0"))) {
            metadata.dads_top_picks = newDadsTopPicks;
        }
        if (keccak256(bytes(newAccessory)) != keccak256(bytes("0"))) {
            metadata.accessory = newAccessory;
        }
        if (keccak256(bytes(newNeck)) != keccak256(bytes("0"))) {
            metadata.neck = newNeck;
        }
        if (keccak256(bytes(newJewelry)) != keccak256(bytes("0"))) {
            metadata.jewelry = newJewelry;
        }
        if (keccak256(bytes(newVibes)) != keccak256(bytes("0"))) {
            metadata.vibes = newVibes;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        MetaDataStruct memory metadata = _metadata[tokenId];
        string memory imageURI = string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));

        bytes memory json = abi.encodePacked(
            '{"name": "NFT #', tokenId.toString(), '",',
            '"description": "An NFT with dynamic traits.",',
            '"image": "', imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Eyes", "value": "', metadata.eyes, '"},',
                '{"trait_type": "Eyewear", "value": "', metadata.eyewear, '"},',
                '{"trait_type": "Hair Style", "value": "', metadata.hair_style, '"},',
                '{"trait_type": "Hair Color", "value": "', metadata.hair_color, '"},',
                '{"trait_type": "Hat", "value": "', metadata.hat, '"},',
                '{"trait_type": "Holding", "value": "', metadata.holding, '"},',
                '{"trait_type": "Shirt", "value": "', metadata.shirt, '"},',
                '{"trait_type": "Dad Joke", "value": "', metadata.dad_joke, '"},',
                '{"trait_type": "Facial Hair", "value": "', metadata.facial_hair, '"},',
                '{"trait_type": "Mouth", "value": "', metadata.mouth, '"},',
                '{"trait_type": "Skin", "value": "', metadata.skin, '"},',
                '{"trait_type": "Dads Top Picks", "value": "', metadata.dads_top_picks, '"},',
                '{"trait_type": "Accessory", "value": "', metadata.accessory, '"},',
                '{"trait_type": "Neck", "value": "', metadata.neck, '"},',
                '{"trait_type": "Jewelry", "value": "', metadata.jewelry, '"},',
                '{"trait_type": "Vibes", "value": "', metadata.vibes, '"}',
            ']}'
        );

        string memory jsonBase64 = Base64Upgradeable.encode(json);
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    function airdrop(address[] calldata _tokenOwners, uint[] calldata _tokenIds) external onlyOwner {
        require(_tokenOwners.length == _tokenIds.length, "CryptoMoms: tokenOwners and tokenIds length mismatch");
        for (uint i = 0; i < _tokenOwners.length; i++) {
            _safeMint(_tokenOwners[i], _tokenIds[i]); // this emits a Transfer event during the _mint function call
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721CUpgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721CUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }
}
