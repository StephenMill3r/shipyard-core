// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract ShoeboxMinting is ERC1155, Ownable, ERC1155Supply {
    uint256 public constant SHOEBOX_ID = 0; // Shoebox tokenId 0
    uint256 public totalShoeboxesMinted;
    uint256 public totalShoeboxesLimit = 10000;

    // Minting phases with price
    struct MintPhase {
        bool active;
        uint256 price; // ETH price for this phase
        uint256 totalAvailable;
    }
    
    // Mint phases stored
    mapping(uint256 => MintPhase) public mintPhases;
    uint256 public currentPhase;

    event ShoeboxMinted(address indexed user, uint256 quantity, uint256 phase);

    constructor(string memory uri) ERC1155(uri) {}

    // Start minting for a specific phase
    function startMintingPhase(uint256 phase, uint256 price, uint256 totalAvailable) external onlyOwner {
        mintPhases[phase] = MintPhase({
            active: true,
            price: price,
            totalAvailable: totalAvailable
        });
        currentPhase = phase;
    }

    // Stop minting for the current phase
    function stopMintingPhase(uint256 phase) external onlyOwner {
        mintPhases[phase].active = false;
    }

    // Mint shoeboxes during the active phase
    function mintShoebox(uint256 quantity) external payable {
        MintPhase memory phase = mintPhases[currentPhase];
        require(phase.active, "Minting is not active");
        require(msg.value == phase.price * quantity, "Incorrect ETH amount");
        require(totalShoeboxesMinted + quantity <= phase.totalAvailable, "Exceeds available shoeboxes in this phase");
        require(totalShoeboxesMinted + quantity <= totalShoeboxesLimit, "Exceeds total shoeboxes limit");

        totalShoeboxesMinted += quantity;
        _mint(msg.sender, SHOEBOX_ID, quantity, "");

        emit ShoeboxMinted(msg.sender, quantity, currentPhase);
    }

    // Override functions from ERC1155 and ERC1155Supply
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
