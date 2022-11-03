//This is an example on how to call self destruct on one contract and force send ether to another contract
// Code via smart contract programmer https://youtu.be/ajCsPRl5S3Q

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

contract Kill{

    constructor() payable{}

    function kill() external{
        selfdestruct(payable(msg.sender));
    }

    function testCall() external pure returns(uint){
        return 123;
    }
}

contract Helper{
    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function kill(Kill _kill) external {
        _kill.kill();
    }
}
