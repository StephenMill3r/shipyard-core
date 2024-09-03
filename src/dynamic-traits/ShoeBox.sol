// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ShoeBox is
    ERC1155,
    Pausable,
    Ownable,
    ReentrancyGuard,
    ERC2981
{
    using Strings for string;
    using SafeERC20 for IERC20;

    struct PhaseConfig {
        mapping(address => uint256) addressesMintQtyAllowed;
        mapping(address => uint256) addressesMintedCount;
        uint256 mintPrice;
        address mintToken;
        uint256 maxPerMintTx;
        uint256 phaseEndTime;
        uint256 phaseStartTime;
        bool isPublicPhase;
    }

    uint256 public MAX_MINTING_SUPPLY = 10000;
    mapping(string => PhaseConfig) public phaseConfigs;
    string public activePhase = "INITIAL";
    string public uriOfImage = "";

    uint256 public airdropMaticPerSassy = 0;

    event Mint(address indexed to, uint indexed quantity);
    event CrossChainMint(
        address indexed to,
        uint indexed quantity,
        string indexed transactionHash
    );
    event PhaseChange(string indexed previousePhase, string indexed newPhase);
    event Received(address indexed sender, uint256 value);

    function mint(uint256 quantity) external nonReentrant {
        IERC20 paymentToken = IERC20(phaseConfigs[activePhase].mintToken);
        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            quantity * phaseConfigs[activePhase].mintPrice
        );
        _mintToQuantity(msg.sender, quantity);
    }

    function airdrop(
        address[] calldata addresses,
        uint256[] calldata quantity
    ) external onlyOwner {
        require(
            addresses.length == quantity.length,
            "Addresses and quantity must be the same length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                totalSupply() + quantity[i] <= MAX_MINTING_SUPPLY,
                "Overminted"
            );
            _mint(addresses[i], 1, quantity[i], "");
            if (airdropMaticPerSassy > 0) {
                payable(addresses[i]).transfer(
                    airdropMaticPerSassy * quantity[i]
                );
            }
            emit Mint(addresses[i], quantity[i]);
        }
    }

    function crossChain(
        address to,
        uint256 quantity,
        string calldata mainnetTransactionHash
    ) external onlyOwner {
        _mintToQuantity(to, quantity);
        emit CrossChainMint(to, quantity, mainnetTransactionHash);
    }

    function _mintToQuantity(address to, uint256 quantity) private {
        if (!phaseConfigs[activePhase].isPublicPhase) {
            require(
                phaseConfigs[activePhase].addressesMintQtyAllowed[to] >=
                    phaseConfigs[activePhase].addressesMintedCount[to] +
                        quantity,
                "You are not allowed to mint this many tokens in this phase"
            );
        }

        if (phaseConfigs[activePhase].phaseStartTime != 0) {
            require(
                phaseConfigs[activePhase].phaseStartTime <= block.timestamp,
                "Minting is not available at this time"
            );
        }

        if (phaseConfigs[activePhase].phaseEndTime != 0) {
            require(
                phaseConfigs[activePhase].phaseEndTime >= block.timestamp,
                "Minting is not available at this time"
            );
        }

        require(
            phaseConfigs[activePhase].maxPerMintTx >= quantity,
            "You are trying to mint too many in a single transaction"
        );

        require(totalSupply() + quantity <= MAX_MINTING_SUPPLY, "Sold out");

        _mint(to, 1, quantity, "");
        phaseConfigs[activePhase].addressesMintedCount[to] += quantity;

        emit Mint(to, quantity);
    }

    function setActivePhase(
        string calldata phaseName
    ) external onlyOwner returns (string memory ActivePhaseName) {
        activePhase = phaseName;
        return activePhase;
    }

    function getAddressTotalMintEligibilityForPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintQtyAllowed) {
        return phaseConfigs[phase].addressesMintQtyAllowed[addr];
    }

    function getAddressMintedQtyInPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintedQty) {
        return phaseConfigs[phase].addressesMintedCount[addr];
    }

    function getAddressRemainingMintEligibilityForPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintQtyAllowed) {
        return (phaseConfigs[phase].addressesMintQtyAllowed[addr] -
            phaseConfigs[phase].addressesMintedCount[addr]);
    }

    function getTotalMinted() external view returns (uint256 totalMinted) {
        return totalSupply();
    }

    function getRemainingMintable()
        external
        view
        returns (uint256 remainingMintable)
    {
        return MAX_MINTING_SUPPLY - totalSupply();
    }

    function addPhase(
        string calldata phaseName,
        address[] calldata addresses,
        uint256[] calldata mintQtyAllowed,
        uint256 mintPrice,
        address mintToken,
        uint256 phaseEndTime,
        uint256 phaseStartTime,
        bool isPublicPhase
    ) external onlyOwner returns (string memory newPhaseName) {
        require(
            addresses.length == mintQtyAllowed.length,
            "Addresses and mintQtyAllowed must be the same length"
        );
        PhaseConfig storage phaseConfig = phaseConfigs[phaseName];
        for (uint256 i = 0; i < addresses.length; i++) {
            phaseConfig.addressesMintQtyAllowed[addresses[i]] = mintQtyAllowed[
                i
            ];
        }
        phaseConfig.mintPrice = mintPrice;
        phaseConfig.mintToken = mintToken;
        phaseConfig.maxPerMintTx = 30;
        phaseConfig.phaseEndTime = phaseEndTime;
        phaseConfig.phaseStartTime = phaseStartTime;
        phaseConfig.isPublicPhase = isPublicPhase;
        return phaseName;
    }

    function withdrawToken(address tokenContractAddress) external onlyOwner {
        IERC20 token = IERC20(tokenContractAddress);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function setImageURI(string calldata newURI) external onlyOwner {
        uriOfImage = newURI;
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "ShoeBox",',
            '"description": "What could be inside?",',
            '"image": "',
            uriOfImage,
            '",',
            '"attributes": []',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }


    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
