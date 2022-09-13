// This basic contract allows the user to add an item to the chain that can be purchased for the chosen listed price.
// The contract has a mapping that allows the users to see the price, descrition, and owner of an item purchased. 

pragma solidity^0.8.7;
//SPDX-License-Identifier: MIT

contract supplyChain{

    address payable owner;

    struct item{
        uint price;
        string description;
        address buyer;
    }

    mapping(uint=> item) public items;
    uint private counter= 0;

    modifier onlyOwner{
        require(owner==msg.sender, "You are not the owner");
        _;
    }

    modifier PaidEnough(uint _price){
        require(msg.value >= _price);
        _;
    }

    constructor(){
        owner= payable (msg.sender);
    }

    function add(uint _price, string memory _desc) public onlyOwner{
        items[counter]= item(_price, _desc, address(0));
        counter ++;
    }

    function buy(uint _id) public payable PaidEnough(msg.value){
        owner.transfer(msg.value);
        items[_id].buyer = msg.sender;
    }
}
