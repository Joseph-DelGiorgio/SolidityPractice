/* 
This contract implements an ERC20-compliant token system with additional ownership and safety features. 
The `Ownable` contract defines an `owner` variable and a constructor that sets the `owner` to the contract deployer. 
It also includes a `onlyOwner` modifier that can be used to restrict certain functions to only be called by the owner, and 
a `transferOwnership` function to allow the owner to transfer ownership to another address.

The `SafeMath` contract provides basic arithmetic functions with overflow and underflow protection. 
The `Token` contract inherits both `Ownable` and `SafeMath` and implements the standard ERC20 functions 
such as `transfer`, `approve`, and `transferFrom`. It also includes additional functions for modifying 
allowances and minting new tokens.

This contract is just an example and should not be used as-is in production.
*/


pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "The new owner address cannot be 0.");
        owner = newOwner;
    }
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "Overflow error in addition.");
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "Underflow error in subtraction.");
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Overflow error in multiplication.");
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "Division by zero error.");
        c = a / b;
    }
}

contract Token is Ownable, SafeMath {
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint public totalSupply = 100000000 * (10 ** uint256(decimals));

    mapping(address =>uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

  function transfer(address to, uint value) public {
    require(balances[msg.sender] >= value, "Insufficient balance.");
    balances[msg.sender] = safeSub(balances[msg.sender], value);
    balances[to] = safeAdd(balances[to], value);
    emit Transfer(msg.sender, to, value);
  }

  function approve(address spender, uint value) public {
    allowances[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
  }

  function transferFrom(address from, address to, uint value) public {
    require(balances[from] >= value, "Insufficient balance.");
    require(allowances[from][msg.sender] >= value, "Insufficient allowance.");
    balances[from] = safeSub(balances[from], value);
    allowances[from][msg.sender] = safeSub(allowances[from][msg.sender], value);
    balances[to] = safeAdd(balances[to], value);
    emit Transfer(from, to, value);
  }

  function increaseAllowance(address spender, uint addedValue) public {
    allowances[msg.sender][spender] = safeAdd(allowances[msg.sender][spender], addedValue);
    emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
  }

  function decreaseAllowance(address spender, uint subtractedValue) public {
    allowances[msg.sender][spender] = safeSub(allowances[msg.sender][spender], subtractedValue);
    emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
  }

  function mint(address to, uint value) public onlyOwner {
    balances[to] = safeAdd(balances[to], value);
    totalSupply = safeAdd(totalSupply, value);
    emit Transfer(address(0), to, value);
  }

}

