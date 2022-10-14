//This contract was used as my smart contract for my "Buy Me A Coffee" Dapp built from a lesson on alchemy.
//video link: https://youtu.be/cxxKdJk55Lk

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BuyMeACoffee{

    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    Memo[] memos;

    address payable owner;

    constructor(){
        owner= payable (msg.sender);
    }

    function buyCoffee(string memory _name, string memory _message) public payable{
        require(msg.value >0, "can't buy coffee with 0 eth");

        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    function withdrawTips() public {
        address(this).balance;
        require(owner.send(address(this).balance));
    }

    function getMemos() public view returns(Memo[] memory){
        return memos;
    }
}
