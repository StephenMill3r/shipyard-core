// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.19;

import "./erc721a/contracts/ERC721A.sol";
import "./erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/** 
@title ShoeBox
*/
contract ShoeBox is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    Pausable,
    Ownable,
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

    // NFT state variables
    uint256 public MAX_MINTING_SUPPLY = 10000;
    mapping(string => PhaseConfig) public phaseConfigs;
    string public activePhase = "INITIAL";
    string public uriOfImage = "";

    /// @notice event emitted when new Token is minted
    event Mint(address indexed to, uint indexed quantity);

    /// @notice event emitted when a phase is changed
    event PhaseChange(string indexed previousePhase, string indexed newPhase);

    /// @notice event emitted when MATIC is received
    event Received(address indexed sender, uint256 value);

    constructor() ERC721A("CryptoDad ShoeBox", "SHOEBOX") Ownable(msg.sender) {}

    /**
     * @notice The external mint function that will be called by the frontend.
     * @param quantity The quantity of tokens to mint
     * @dev This requires pre-approval to spend the ERC20 mintToken defined in the active phase.
     */
    function mint(uint256 quantity) external {
        IERC20 paymentToken = IERC20(phaseConfigs[activePhase].mintToken);
        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            quantity * phaseConfigs[activePhase].mintPrice
        );
        _mintToQuantity(msg.sender, quantity);
    }

    /**
     * @notice This function will perform a bulk airdrop of tokens.
     * @param addresses The addresses to airdrop to
     * @param quantity The quantity of tokens to airdrop to each address based on their L1 token holdings
     * @dev This function bypasses any phase checks
     */
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
                _totalMinted() + quantity[i] <= MAX_MINTING_SUPPLY,
                "Overminted"
            );
            // Perform the real mint
            _mint(addresses[i], quantity[i]);
            emit Mint(addresses[i], quantity[i]);
        }
    }

    /**
     * @notice a Common minting function for minting tokens. Performs validation of active minting phase
     * @param to The address to mint to
     * @param quantity the number of tokens to mint
     */
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

        require(_totalMinted() + quantity <= MAX_MINTING_SUPPLY, "Sold out");

        // Perform the real mint
        _mint(to, quantity);
        phaseConfigs[activePhase].addressesMintedCount[to] += quantity;

        emit Mint(to, quantity);
    }

    /**
     * @notice Sets active phase to a new value
     * @param phaseName the new phase to set active
     */
    function setActivePhase(
        string calldata phaseName
    ) external onlyOwner returns (string memory ActivePhaseName) {
        activePhase = phaseName;
        return activePhase;
    }

    /**
     * @notice Lookup of how many tokens an address is allowed to mint in a phase, regardless of if they have minted any yet or not.
     * @param addr The address to lookup
     * @param phase The phase to check
     * @dev Does not need to be the active phase to perform a lookup
     */
    function getAddressTotalMintEligibilityForPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintQtyAllowed) {
        return phaseConfigs[phase].addressesMintQtyAllowed[addr];
    }

    /**
     * @notice Lookup of how many tokens an address has already minted in a phase
     * @param addr The address to lookup
     * @param phase The phase to check
     * @dev Does not need to be the active phase to perform a lookup
     */
    function getAddressMintedQtyInPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintedQty) {
        return phaseConfigs[phase].addressesMintedCount[addr];
    }

    /**
     * @notice Lookup of how many tokens an address can still mint in a phase
     * @param addr The address to lookup
     * @param phase The phase to check
     * @dev Does not need to be the active phase to perform a lookup
     */
    function getAddressRemainingMintEligibilityForPhase(
        address addr,
        string calldata phase
    ) external view returns (uint256 mintQtyAllowed) {
        return (phaseConfigs[phase].addressesMintQtyAllowed[addr] -
            phaseConfigs[phase].addressesMintedCount[addr]);
    }

    /**
     * @notice expose number minted instead of totalSupply for use in frontend UI
     */
    function getTotalMinted() external view returns (uint256 totalMinted) {
        return _totalMinted();
    }

    /**
     * @notice expose number remaining for convenience to frontend UI
     */
    function getRemainingMintable()
        external
        view
        returns (uint256 remainingMintable)
    {
        return MAX_MINTING_SUPPLY - _totalMinted();
    }

    /**
     * @notice adds a new minting phase configuration to the contract based on name
     * @param phaseName the name of the phase to add
     * @param addresses the addresses to allow minting for (NOTE: Parallel list with minQtyAllowed)
     * @param mintQtyAllowed the quantity of tokens allowed to be minted for each address (NOTE: Parallel list with addresses)
     * @param mintPrice the price of each mint in Wei (assumed 18 decimals for the taoken of payment)
     * @param mintToken the address of the Polygon ERC20 to use for payment
     * @param phaseEndTime the timestamp of the end of the phase. If zero then no end time
     * @param phaseStartTime the timestamp of the start of the phase. If zero then no start time
     * @param isPublicPhase if true then anyone can mint. If false then only addresses in the addresses list can mint
     */
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
        // Turn the addresses from a list to a mapping for easier lookup
        for (uint256 i = 0; i < addresses.length; i++) {
            phaseConfig.addressesMintQtyAllowed[addresses[i]] = mintQtyAllowed[
                i
            ];
        }
        phaseConfig.mintPrice = mintPrice;
        phaseConfig.mintToken = mintToken;
        phaseConfig.maxPerMintTx = 30; // This is hardcoded per ERC721A documentation guidance
        phaseConfig.phaseEndTime = phaseEndTime;
        phaseConfig.phaseStartTime = phaseStartTime;
        phaseConfig.isPublicPhase = isPublicPhase;
        return phaseName;
    }

    /**
     * @notice External function for the contract owner to withdraw any ERC20 tokens sent to the contract
     */
    function withdrawToken(address tokenContractAddress) external onlyOwner {
        IERC20 token = IERC20(tokenContractAddress);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function setImageURI(string calldata newURI) external onlyOwner {
        uriOfImage = newURI;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "CryptoDad ShoeBox",',
            '"description": "What could be inside?",',
            '"image": "',
            uriOfImage,
            '",',
            '"animation_url":  "',
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
    ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @dev required to be able to directly receive MATIC
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice External function for the contract owner to withdraw any MATIC sent to the contract.
     * @dev This is only MATIC deposits for airdrops or accidental MATIC sends as there is not currently a mint for MATIC function. For ERC20 withdrawals use withdrawToken
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // PAUSABLE
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
