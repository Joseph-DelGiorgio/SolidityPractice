pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Immutable{

    address public immutable owner= msg.sender;

    uint public x;
    function foo() external{
        require(msg.sender == owner);
        x += 1;
    }
}
