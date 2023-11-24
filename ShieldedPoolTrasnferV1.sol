//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShieldedPool is ReentrancyGuard, Ownable {
    enum WithdrawalMethod { Immediate, Delayed, MultiSig }

    mapping(bytes32 => mapping(address => uint256)) private balances;
    mapping(bytes32 => bool) private usedStealthAddresses;
    mapping(address => bool) private supportedTokens;

    uint256 public withdrawalDelay;
    mapping(bytes32 => uint256) public withdrawalUnlockTime;
    mapping(bytes32 => bool) public multiSigWithdrawalEnabled;
    mapping(bytes32 => address[]) public multiSigWithdrawalSigners;
    mapping(bytes32 => mapping(address => bool)) public isMultiSigWithdrawalSigner;

    event Deposit(bytes32 indexed stealthAddress, address indexed token, uint256 amount);
    event Withdrawal(bytes32 indexed stealthAddress, address indexed token, uint256 amount, WithdrawalMethod method);
    event StealthAddressGenerated(bytes32 indexed stealthAddress);
    event StealthAddressUsed(bytes32 indexed stealthAddress);
    event WithdrawalDelayed(bytes32 indexed stealthAddress, uint256 unlockTime);
    event MultiSigWithdrawalEnabled(bytes32 indexed stealthAddress, address[] signers);
    event MultiSigWithdrawalSigned(bytes32 indexed stealthAddress, address indexed signer);
    event MultiSigWithdrawalCompleted(bytes32 indexed stealthAddress, uint256 amount);

    modifier onlyStealthAddressOwner(bytes32 stealthAddress) {
        require(msg.sender == address(0) || keccak256(abi.encodePacked(msg.sender)) == stealthAddress, "Not stealth address owner");
        _;
    }

    constructor(uint256 _withdrawalDelay) {
        withdrawalDelay = _withdrawalDelay;
    }

    function generateStealthAddress() internal returns (bytes32) {
        bytes32 stealthAddress = keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)));
        require(!usedStealthAddresses[stealthAddress], "Stealth address already used");
        usedStealthAddresses[stealthAddress] = true;
        emit StealthAddressGenerated(stealthAddress);
        return stealthAddress;
    }

    function depositERC20(address token, uint256 amount) external nonReentrant {
        require(supportedTokens[token], "Unsupported token");
        bytes32 stealthAddress = generateStealthAddress();
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[stealthAddress][token] += amount;
        emit Deposit(stealthAddress, token, amount);
    }

    function withdrawERC20(bytes32 stealthAddress, address token, uint256 amount, WithdrawalMethod method) external onlyStealthAddressOwner(stealthAddress) nonReentrant {
        require(supportedTokens[token], "Unsupported token");
        require(amount <= balances[stealthAddress][token], "Insufficient balance");

        if (method == WithdrawalMethod.Delayed) {
            require(withdrawalUnlockTime[stealthAddress] == 0, "Delayed withdrawal already scheduled");
            withdrawalUnlockTime[stealthAddress] = block.timestamp + withdrawalDelay;
            emit WithdrawalDelayed(stealthAddress, withdrawalUnlockTime[stealthAddress]);
        } else if (method == WithdrawalMethod.MultiSig) {
            require(multiSigWithdrawalEnabled[stealthAddress], "MultiSig withdrawal not enabled");
            require(!isMultiSigWithdrawalSigner[stealthAddress][msg.sender], "Already signed");
            isMultiSigWithdrawalSigner[stealthAddress][msg.sender] = true;
            multiSigWithdrawalSigners[stealthAddress].push(msg.sender);
            emit MultiSigWithdrawalSigned(stealthAddress, msg.sender);

            if (multiSigWithdrawalSigners[stealthAddress].length == 2) {
                completeMultiSigWithdrawal(stealthAddress, token, amount);
            }
        }

        balances[stealthAddress][token] -= amount;

        if (method == WithdrawalMethod.Immediate) {
            IERC20(token).transfer(msg.sender, amount);
            emit Withdrawal(stealthAddress, token, amount, method);
        }
    }

    function completeDelayedWithdrawal(bytes32 stealthAddress, address token, uint256 amount) external onlyOwner nonReentrant {
        require(withdrawalUnlockTime[stealthAddress] != 0 && block.timestamp >= withdrawalUnlockTime[stealthAddress], "Withdrawal not yet unlocked");
        withdrawalUnlockTime[stealthAddress] = 0;
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawal(stealthAddress, token, amount, WithdrawalMethod.Delayed);
    }

    function enableMultiSigWithdrawal(bytes32 stealthAddress, address[] memory signers) external onlyStealthAddressOwner(stealthAddress) {
        require(!multiSigWithdrawalEnabled[stealthAddress], "MultiSig withdrawal already enabled");
        require(signers.length == 2, "Invalid number of signers");
        multiSigWithdrawalEnabled[stealthAddress] = true;
        multiSigWithdrawalSigners[stealthAddress] = signers;
        emit MultiSigWithdrawalEnabled(stealthAddress, signers);
    }

    function completeMultiSigWithdrawal(bytes32 stealthAddress, address token, uint256 amount) internal {
        require(multiSigWithdrawalEnabled[stealthAddress], "MultiSig withdrawal not enabled");
        require(multiSigWithdrawalSigners[stealthAddress].length == 2, "Invalid number of signers");
        for (uint256 i = 0; i < 2; i++) {
            require(isMultiSigWithdrawalSigner[stealthAddress][multiSigWithdrawalSigners[stealthAddress][i]], "Not all signers have signed");
        }
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawal(stealthAddress, token, amount, WithdrawalMethod.MultiSig);
        emit MultiSigWithdrawalCompleted(stealthAddress, amount);

        // Reset multi-sig withdrawal state
        multiSigWithdrawalEnabled[stealthAddress] = false;
        delete multiSigWithdrawalSigners[stealthAddress];
        for (uint256 i = 0; i < 2; i++) {
            isMultiSigWithdrawalSigner[stealthAddress][multiSigWithdrawalSigners[stealthAddress][i]] = false;
        }
    }

    function transferFunds(bytes32 sourceStealthAddress, bytes32 destinationStealthAddress, address token, uint256 amount) external onlyStealthAddressOwner(sourceStealthAddress) onlyStealthAddressOwner(destinationStealthAddress) nonReentrant {
        require(supportedTokens[token], "Unsupported token");
        require(amount <= balances[sourceStealthAddress][token], "Insufficient balance");

        balances[sourceStealthAddress][token] -= amount;
        balances[destinationStealthAddress][token] += amount;

        emit Withdrawal(sourceStealthAddress, token, amount, WithdrawalMethod.Immediate);
        emit Deposit(destinationStealthAddress, token, amount);
    }

    function getBalance(bytes32 stealthAddress, address token) external view returns (uint256) {
        return balances[stealthAddress][token];
    }

    function addSupportedToken(address token) external onlyOwner {
        supportedTokens[token] = true;
    }

    function removeSupportedToken(address token) external onlyOwner {
        supportedTokens[token] = false;
    }

    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token];
    }

    function markStealthAddressAsUsed(bytes32 stealthAddress) external onlyOwner {
        usedStealthAddresses[stealthAddress] = true;
        emit StealthAddressUsed(stealthAddress);
    }
}

