pragma solidity^0.8.0;
// SPDX-License-Identifier: MIT

contract HotelRoom{

    enum Statuses{
        vacant, 
        occupied
    }
    Statuses public currentStatus; 

    event Occupy(address _occupant, uint _value);

    address payable owner;

    constructor(){
        owner= payable(msg.sender);
        currentStatus= Statuses.vacant;
    }

    modifier onlyWhileVacant{
        require(currentStatus==Statuses.vacant, "The room is occupied");
        _;
    }

    modifier costs(uint amount){
        require(msg.value>=amount, "Not enough ETH provided");
        _;
    }

    function book() public payable onlyWhileVacant costs(2 ether){   
        currentStatus =Statuses.occupied;

        (bool sent, bytes memory data)= owner.call{value: msg.value}("");
        require(sent);

        emit Occupy(msg.sender, msg.value);
    }
}
