// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/dynamic-traits/CryptoDadsOnchain.sol";

contract InitializeTraitsScript is Script {
    CryptoDadsOnchain public contractInstance;

    address public contractAddress = 0x3ce8f7c7302D6e4273B579afD3A3788E57758139;

    struct TraitData {
        uint256 tokenId;
        string[17] keys;
        string[17] values;
    }

    // Declare the array of TraitData here
    TraitData[] public allTraits;

    function run() external {
        vm.startBroadcast();

        contractInstance = CryptoDadsOnchain(contractAddress);


        allTraits[0] = TraitData(1, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Pool Day Blue", "Light", "Brown Bearded", "Farmer", "Disoriented", "I once had a dream I was floating in an ocean of orange soda. It was more of a fanta sea.", "Military", "", "", "", "", "", "", "", "", ""]);
        allTraits[1] = TraitData(2, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Lawn Green", "Dark", "Black Gentleman Stache", "Braces", "Blanked", "I don't play soccer because I enjoy the sport. I'm just doing it for kicks!", "Frat Boy", "", "Black", "Devil Horns", "", "", "Bag Holder", "", "", ""]);
        allTraits[2] = TraitData(3, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Lime Green", "Tatted", "Red Bearded", "Buck", "Rolled Eyes", "Singing in the shower is fun until you get soap in your mouth. Then it's a soap opera.", "Hoodie", "", "", "", "", "", "", "", "", ""]);
        allTraits[3] = TraitData(4, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Coral", "Tatted", "Blonde Bearded", "Cigar", "Conflict Maxi", "A cheeseburger walks into a bar. The bartender says, 'Sorry, we don't serve food here.'", "Warehouse Manager", "", "", "", "", "", "Triple Loop Earring", "", "", ""]);
        allTraits[4] = TraitData(5, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Purple", "Light", "Black Bearded", "Buck", "Bitcoin Maxi", "What did one wall say to the other? I'll meet you at the corner.", "Degenerate", "", "", "", "", "", "", "", "", ""]);
        allTraits[5] = TraitData(6, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Sky Blurple", "Light", "Blonde GOATee", "Tobacco Pipe", "Ape Tears", "That car looks nice but the muffler seems exhausted.", "Lumberjack", "", "Brown", "Ponytail", "Harry Plotter", "", "", "", "", ""]);
        allTraits[6] = TraitData(7, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Lime Green", "Medium", "Brown Bearded", "Farmer", "Ape Tears", "I got carded at a liquor store, and my Blockbuster card accidentally fell out. The cashier said never mind.", "Turtleneck", "", "", "", "", "", "", "", "", ""]);
        allTraits[7] = TraitData(8, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Dad-O-Mite", "Pool Day Blue", "Light", "Grey Fu Manchu", "Smurkio", "Arghh!", "What does a lemon say when it answers the phone? Yellow!", "Leather Jacket", "", "Grey", "Manbun", "", "", "Loop Earring", "", "", ""]);
        allTraits[8] = TraitData(9, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Purple", "Medium", "Grey Bearded", "Cigar", "Trippin'", "How do you make 7 even? Take away the s.", "Lumberjack", "", "", "", "", "", "", "", "", ""]);
        allTraits[9] = TraitData(10, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Lime Green", "Sunburnt", "", "Vampire", "Bag Holder", "Shout out to my fingers. I can count on all of them.", "Turtleneck", "Santa", "Black", "Mullet", "", "", "", "", "", ""]);
        allTraits[10] = TraitData(11, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Pool Day Blue", "Dark", "Blonde Bearded", "Buck", "Disoriented", "How do you make a tissue dance? You put a little boogie in it.", "Lumberjack", "", "Grey", "Curly Long", "", "", "", "", "", ""]);
        allTraits[10] = TraitData(11, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Pool Day Blue", "Dark", "Blonde Bearded", "Buck", "Disoriented", "How do you make a tissue dance? You put a little boogie in it.", "Lumberjack", "", "Grey", "Curly Long", "", "", "", "", "", ""]);
        allTraits[11] = TraitData(12, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "ToolBox Yellow", "Tatted", "Grey Bearded", "Buck", "Eastern", "Why do bees have sticky hair? Because they use a honeycomb.", "Life Vest", "", "", "", "", "", "Triple Loop Earring", "", "", ""]);
        allTraits[12] = TraitData(13, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Steel", "Medium", "", "Buck", "Bag Holder", "What happens when a strawberry gets run over crossing the street? Traffic jam.", "Hoodie", "Night Cap", "Red", "Curly Long", "", "", "", "Fishing Day", "", ""]);
        allTraits[13] = TraitData(14, ["Vibes", "Background", "Skin", "Facial Hair", "Mouth", "Eyes", "Dad Joke", "Clothes", "Hat", "Hair Color", "Hair Style", "Eyewear", "Neck", "Jewelry", "Holding", "Accessory", "Dad's Top Pick"], ["Old School", "Pool Day Blue", "Light", "", "Buck", "Bag Holder", "When two vegans get in an argument, is it still called a beef?", "Tank Top", "", "", "", "", "", "", "", "", ""]);


        // Arrays to store all trait data
        uint256[] memory tokenIds = new uint256[](allTraits.length);
        string[17][] memory keysArray = new string[17][](allTraits.length);
        string[17][] memory valuesArray = new string[17][](allTraits.length);

        // Populate the arrays
        for (uint256 i = 0; i < allTraits.length; i++) {
            tokenIds[i] = allTraits[i].tokenId;
            keysArray[i] = allTraits[i].keys;
            valuesArray[i] = allTraits[i].values;
        }

        // Call the batch initializer function in the contract
        contractInstance.initializeBatchTraits(tokenIds, keysArray, valuesArray);

        vm.stopBroadcast();
    }
}
