  // THIS IS FOR CRYPTOMOMS / CRYPTODADS MAIN NFT CONTRACT 
   
  
// USE THIS FROM THE SASSY TRAITS CONTRACT INSTEAD OF HARDCODING THE TRAITS LIKE ONCHAIN DINOS
// Change the trait info to be fields needed not what was in sassy contract. Include dads and moms together with a field that distinguishes them.
        function updateTraitInfo(uint256[] calldata traitIDs, string[] calldata names, string[] calldata sports, string[] calldata categories, string[] calldata rarities) external onlyOwner returns (uint256 numUpdated) {
        require(traitIDs.length == sports.length && traitIDs.length == categories.length && traitIDs.length == rarities.length, "ShreddingSassyTrait: Arrays must be same length");
        for (uint i = 0; i < traitIDs.length; i++) {
            traitIDToTraitInfo[traitIDs[i]] = TraitInfo(traitIDs[i], names[i], sports[i], categories[i], rarities[i]);
        }
        return traitIDs.length;
    }


    //use tokenIDToTraitID which is set at mint time to the next tokenid (of the trait nft) and tokenIDToTraitID[tokenID] = traitID this ties the trait to the token. TraitIDs are set in the UpdateTraitInfo function. 
    //This should be set on both the trait contract and collection contract. ?
    // This is the function that will be called in the tokenURI function to get the traits for the token.
        
        
        /// Dino Trait Struct
    struct TraitStruct {
        uint body;
        uint chest;
        uint eye;
        uint face;
        uint feet;
        uint head;
        uint spike;
    }

//// Store a dinos traits here - this is filled when minted!
    mapping(uint => TraitStruct) public tokenTraits;

//setting traitsstruct
            TraitStruct memory newTraits = TraitStruct({
            body: randBody, // make these trait IDs
            chest: randChest,
            eye: randEyes,
            face: randFace,
            feet: randFeet,
            head: randHead,
            spike: randSpikes
        });

        // Assign the generated traits to the token
        tokenTraits[_tokenID] = newTraits;


  // ONCHAIN TOKENURI FUNCTION GET DINO TRAITS FUNCTION NEEDS TO BE REMADE.
   function _tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Get image
        string memory image = buildSVG(tokenId);

        // Encode SVG data to base64
        string memory base64Image = ''//change to centralized URL

        // Build JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name": "OnChain Dinos #', Strings.toString(tokenId), '",',
                '"description": "OnChain Dinos have hatched on Base - 100% stored on the Blockchain",',
                '"attributes": [', _getDinoTraits(tokenId), '],',
                '"image": "data:image/svg+xml;base64,', base64Image, '"}' //change to centralized URL
            )
        );

        // Encode JSON data to base64
        string memory base64Json = Base64.encode(bytes(json));

        // Construct final URI
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }


        function _getDinoTraits(uint tokenid) internal view returns (string memory) {

        TraitStruct memory traits = tokenTraits[tokenid];

        string memory DinoEggs = Strings.toString(DinoEggs[tokenid]);

        string memory metadata = string(abi.encodePacked(
        '{"trait_type":"Dino Eggs","display_type": "number", "value":"', DinoEggs, '"},',
        '{"trait_type":"Body", "value":"', body_traits[traits.body], '"},',
        '{"trait_type":"Chest", "value":"', chest_traits[traits.chest], '"},',
        '{"trait_type":"Eyes", "value":"', eye_traits[traits.eye], '"},',
        '{"trait_type":"Face", "value":"', face_traits[traits.face], '"},',
        '{"trait_type":"Feet", "value":"', feet_traits[traits.feet], '"},',
        '{"trait_type":"Head", "value":"', head_traits[traits.head], '"},',
        '{"trait_type":"Spikes", "value":"', spike_traits[traits.spike], '"}'
        ));

        return metadata;

    }
















// SCRIPT FOR DEPLOYING UPGRADEABLE CONTRACTS WITH FOUNDRY
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/MyUpgradeableToken.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {

    function run() external returns (address, address) {
        //we need to declare the sender's private key here to sign the deploy transaction
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployTransparentProxy(
            "MyUpgradeableToken.sol",
            msg.sender,
            abi.encodeCall(MyUpgradeableToken.initialize, (msg.sender))
        );

        // Get the implementation address
        address implementationAddress = Upgrades.getImplementationAddress(
            _proxyAddress
        );

        vm.stopBroadcast();

        return (implementationAddress, _proxyAddress);
    }
}

//forge script script/01_Deploy.s.sol:DeployScript --sender ${YOUR_PUBLIC_KEY} --rpc-url mumbai --broadcast -vvvv