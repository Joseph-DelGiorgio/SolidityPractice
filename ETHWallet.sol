//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract wallet{
    address payable public owner;
    mapping(address=>uint) public balance;

    constructor(){
        owner = payable (msg.sender);
    }

    function deposit() payable public{
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public{
        require(msg.sender == owner, "only the owner can withdraw funds!");
        payable (msg.sender).transfer(_amount);
    }

    function checkBalance() external view returns(uint){
        return address (this).balance;
    }
}
