// This was a guided excersise via Artur Chmaro Youtube Channel. Video link: https://youtu.be/Uy2cELEZoQc
// Inorder to stake, you must also create an NFT contract to put in the constructor

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";


contract NftStaker{
    IERC1155 public parentNFT;

    struct Stake{
        uint tokenId;
        uint amount;
        uint timestamp;
    }

    //map staker address to stake details
    mapping(address=> Stake) public stakes;

    //map staker to total staking time
    mapping(address=>uint) public stakingTime;

    constructor(){
        //change address to NFT contract address
        parentNFT= IERC1155(0xEc29164D68c4992cEdd1D386118A47143fdcF142);
    }

    function stake(uint _tokenId, uint _amount) public{
        stakes[msg.sender]= Stake(_tokenId, _amount, block.timestamp);
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "0x00");

    }

    function unstake() public {
        parentNFT.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].tokenId, stakes[msg.sender].amount, "0x00");
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      

    function onERC1155Recieved(
        address operator,
        address from,
        uint id,
        uint value,
        bytes calldata data
    ) external returns(bytes4){
        return bytes4(keccak256("onERC1155Recieved(address,address,uint,uint,bytes"));
    }
}
