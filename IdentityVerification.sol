// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import necessary libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdentityVerification is Ownable {
    struct Identity {
        string fullName;
        string governmentID;
        bool verified;
    }

    mapping(address => Identity) public identities;

    IERC20 public verificationToken;
    uint256 public verificationFee;

    event IdentityCreated(address indexed user, string fullName, string governmentID);
    event IdentityVerified(address indexed user);
    event VerificationFeeUpdated(address indexed owner, uint256 newFee);

    constructor(address _tokenAddress, uint256 _initialFee) {
        verificationToken = IERC20(_tokenAddress);
        verificationFee = _initialFee;
    }

    function createIdentity(string memory _fullName, string memory _governmentID) external payable {
        require(bytes(identities[msg.sender].fullName).length == 0, "Identity already exists");
        require(msg.value >= verificationFee, "Insufficient verification fee");

        // Transfer the verification fee (in ETH) to the owner
        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(msg.value);

        identities[msg.sender] = Identity({
            fullName: _fullName,
            governmentID: _governmentID,
            verified: false
        });

        emit IdentityCreated(msg.sender, _fullName, _governmentID);
    }

    function verifyIdentity(address _userAddress) external onlyOwner {
        require(bytes(identities[_userAddress].fullName).length > 0, "Identity does not exist");
        identities[_userAddress].verified = true;

        emit IdentityVerified(_userAddress);
    }

    function updateVerificationFee(uint256 _newFee) external onlyOwner {
        verificationFee = _newFee;
        emit VerificationFeeUpdated(owner(), _newFee);
    }

    function withdrawTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }

    function withdrawEth(uint256 _amount) external onlyOwner {
        address payable ownerAddress = payable(owner());
        require(address(this).balance >= _amount, "Insufficient ETH balance");
        ownerAddress.transfer(_amount);
    }

    receive() external payable {
        // Fallback function to accept ETH payments for verification fees
    }
}
