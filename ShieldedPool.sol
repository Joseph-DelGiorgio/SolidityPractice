// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ShieldedPool {
    // A mapping to store the balance of each stealth address
    mapping(bytes32 => mapping(address => uint256)) private balances;

    // Mapping to track which ERC-20 tokens are supported
    mapping(address => bool) private supportedTokens;

    // Mapping to track used stealth addresses
    mapping(bytes32 => bool) private usedStealthAddresses;

    // Event emitted when funds are deposited into the shielded pool
    event Deposit(bytes32 indexed stealthAddress, address indexed token, uint256 amount);

    // Event emitted when funds are withdrawn from the shielded pool
    event Withdrawal(bytes32 indexed stealthAddress, address indexed token, uint256 amount);

    // Event emitted when a new stealth address is generated
    event StealthAddressGenerated(bytes32 indexed stealthAddress);

    // Event emitted when a stealth address is marked as used
    event StealthAddressUsed(bytes32 indexed stealthAddress);

    // Function to generate a new stealth address
    function generateStealthAddress() internal returns (bytes32) {
        bytes32 stealthAddress = keccak256(abi.encodePacked(msg.sender, block.number, blockhash(block.number - 1)));
        require(!usedStealthAddresses[stealthAddress], "Stealth address already used");
        usedStealthAddresses[stealthAddress] = true;
        emit StealthAddressGenerated(stealthAddress);
        return stealthAddress;
    }

    // Function to deposit ERC-20 tokens into the shielded pool
    function depositERC20(address token, uint256 amount) external {
        require(supportedTokens[token], "Unsupported token");
        bytes32 stealthAddress = generateStealthAddress();

        // Transfer tokens from the sender to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Add the deposited amount to the balance of the stealth address
        balances[stealthAddress][token] += amount;

        emit Deposit(stealthAddress, token, amount);
    }

    // Function to withdraw ERC-20 tokens from the shielded pool
    function withdrawERC20(address token, uint256 amount, bytes32 secret) external {
        require(supportedTokens[token], "Unsupported token");
        bytes32 stealthAddress = keccak256(abi.encodePacked(secret));
        require(usedStealthAddresses[stealthAddress], "Invalid stealth address");

        // Ensure that the sender owns the stealth address
        require(msg.sender == stealthAddress, "Invalid stealth address");

        // Ensure that the withdrawal amount is not greater than the balance
        require(amount <= balances[stealthAddress][token], "Insufficient balance");

        // Subtract the withdrawn amount from the balance
        balances[stealthAddress][token] -= amount;

        // Transfer tokens to the sender
        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(stealthAddress, token, amount);
    }

    // Function to deposit Ether into the shielded pool
    function depositEther() external payable {
        bytes32 stealthAddress = generateStealthAddress();

        // Add the deposited amount to the balance of the stealth address
        balances[stealthAddress][address(0)] += msg.value;

        emit Deposit(stealthAddress, address(0), msg.value);
    }

    // Function to withdraw Ether from the shielded pool
    function withdrawEther(uint256 amount, bytes32 secret) external {
        bytes32 stealthAddress = keccak256(abi.encodePacked(secret));
        require(usedStealthAddresses[stealthAddress], "Invalid stealth address");

        // Ensure that the sender owns the stealth address
        require(msg.sender == stealthAddress, "Invalid stealth address");

        // Ensure that the withdrawal amount is not greater than the balance
        require(amount <= balances[stealthAddress][address(0)], "Insufficient balance");

        // Subtract the withdrawn amount from the balance
        balances[stealthAddress][address(0)] -= amount;

        // Transfer Ether to the sender
        payable(msg.sender).transfer(amount);

        emit Withdrawal(stealthAddress, address(0), amount);
    }

    // Function to check the balance of a stealth address for a specific token
    function getBalance(bytes32 stealthAddress, address token) external view returns (uint256) {
        return balances[stealthAddress][token];
    }

    // Function to add supported ERC-20 tokens
    function addSupportedToken(address token) external {
        supportedTokens[token] = true;
    }

    // Function to remove supported ERC-20 tokens
    function removeSupportedToken(address token) external {
        supportedTokens[token] = false;
    }

    // Function to check if a token is supported
    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token];
    }

    // Function to mark a stealth address as used (for withdrawal protection)
    function markStealthAddressAsUsed(bytes32 stealthAddress) external {
        usedStealthAddresses[stealthAddress] = true;
        emit StealthAddressUsed(stealthAddress);
    }
}

