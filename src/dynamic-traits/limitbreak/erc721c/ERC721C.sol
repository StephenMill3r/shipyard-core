// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "../utils/CreatorTokenBaseUpgradeable.sol";

/**
 * @title ERC721C
 * @author Limit Break, Inc.
 * @notice Extends OpenZeppelin's ERC721 implementation with Creator Token functionality, which
 *         allows the contract owner to update the transfer validation logic by managing a security policy in
 *         an external transfer validation security policy registry.  See {CreatorTokenTransferValidator}.
 */
abstract contract ERC721CUpgradeable is ERC721Upgradeable, CreatorTokenBaseUpgradeable {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId;
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize; ) {
            _validateBeforeTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize; ) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }
}
