// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title BasicRoyaltiesBase
 * @author Limit Break, Inc.
 * @dev Base functionality of an NFT mix-in contract implementing the most basic form of programmable royalties.
 */
abstract contract BasicRoyaltiesBaseUpgradeable is ERC2981Upgradeable {
    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual override {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual override {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }
}

/**
 * @title BasicRoyaltiesUpgradeable
 * @author Limit Break, Inc.
 * @notice Constructable BasicRoyalties Contract implementation.
 */
abstract contract BasicRoyaltiesUpgradeable is BasicRoyaltiesBaseUpgradeable {

}
