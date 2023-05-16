// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    mapping(address => mapping(bytes32 => uint256)) public traderBalances;

    function addToken(bytes32 ticker, address tokenAddress) external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        traderBalances[msg.sender][ticker] += amount;
    }

    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(traderBalances[msg.sender][ticker] >= amount, "Insufficient balance");
        traderBalances[msg.sender][ticker] -= amount;
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    function trade(bytes32 sourceTicker, bytes32 destinationTicker, uint amount) external {
        require(traderBalances[msg.sender][sourceTicker] >= amount, "Insufficient balance");
        require(IERC20(tokens[sourceTicker].tokenAddress).balanceOf(address(this)) >= amount, "Insufficient liquidity");
        require(IERC20(tokens[destinationTicker].tokenAddress).balanceOf(address(this)) >= amount, "Insufficient liquidity");

        traderBalances[msg.sender][sourceTicker] -= amount;
        traderBalances[msg.sender][destinationTicker] += amount;
    }

    modifier tokenExist(bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0), "Token does not exist");
        _;
    }
}
