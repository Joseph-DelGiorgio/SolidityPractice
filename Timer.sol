pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

contract Timer{

    uint _start;
    uint _end;

    modifier timerOver{
        require(block.timestamp <=_end, "The timer is over");
        _;
    }

    function start() public{
        _start=block.timestamp;
    }

    function end(uint totalTime) public{
        _end= totalTime + _start;
    }

    function getTimeLeft() public timerOver view returns(uint){
        return _end-block.timestamp;
    }
}
