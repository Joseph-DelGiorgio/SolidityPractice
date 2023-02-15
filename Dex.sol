// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract DEX {
    address public owner;
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => uint256)) public orders;

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event Order(address indexed fromToken, address indexed toToken, address indexed user, uint256 fromAmount, uint256 toAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "DEX: Only owner can call this function.");
        _;
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "DEX: Amount must be greater than zero.");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "DEX: Transfer failed.");
        balances[token][msg.sender] += amount;
        emit Deposit(token, msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external {
        require(amount > 0, "DEX: Amount must be greater than zero.");
        require(balances[token][msg.sender] >= amount, "DEX: Insufficient balance.");
        require(IERC20(token).transfer(msg.sender, amount), "DEX: Transfer failed.");
        balances[token][msg.sender] -= amount;
        emit Withdraw(token, msg.sender, amount);
    }

    function makeOrder(address fromToken, address toToken, uint256 fromAmount, uint256 toAmount) external {
        require(fromToken != toToken, "DEX: Tokens must be different.");
        require(fromAmount > 0 && toAmount > 0, "DEX: Amounts must be greater than zero.");
        require(balances[fromToken][msg.sender] >= fromAmount, "DEX: Insufficient balance.");
        orders[fromToken][toToken] += fromAmount;
        balances[fromToken][msg.sender] -= fromAmount;
        emit Order(fromToken, toToken, msg.sender, fromAmount, toAmount);
    }

    function fillOrder(address fromToken, address toToken, address user, uint256 fromAmount, uint256 toAmount) external {
        require(fromToken != toToken, "DEX: Tokens must be different.");
        require(fromAmount > 0 && toAmount > 0, "DEX: Amounts must be greater than zero.");
        require(balances[toToken][msg.sender] >= toAmount, "DEX: Insufficient balance.");
        require(orders[fromToken][toToken] >= fromAmount, "DEX: Insufficient liquidity.");
        require(IERC20(fromToken).transfer(user, fromAmount), "DEX: Transfer failed.");
        require(IERC20(toToken).transferFrom(msg.sender, user, toAmount), "DEX: Transfer failed.");
        orders[fromToken][toToken] -= fromAmount;
        balances[toToken][msg.sender] -= toAmount;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "DEX: New owner cannot be zero address.");
        owner = newOwner;
    }
}
