// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoyaltiesContract {
    address public creator;
    uint256 public royaltyPercentage; // in basis points (1 basis point = 0.01%)

    event RoyaltiesReceived(address indexed payer, uint256 amount);

    constructor(uint256 _royaltyPercentage) {
        creator = msg.sender;
        royaltyPercentage = _royaltyPercentage;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the creator can perform this action");
        _;
    }

    function setRoyaltyPercentage(uint256 _newRoyaltyPercentage) public onlyCreator {
        royaltyPercentage = _newRoyaltyPercentage;
    }

    function receiveRoyalties() public payable {
        require(msg.value > 0, "Royalties amount must be greater than 0");
        uint256 royalties = (msg.value * royaltyPercentage) / 10000; // Calculate royalties in wei
        (bool success, ) = payable(creator).call{value: royalties}("");
        require(success, "Royalties payment failed");
        emit RoyaltiesReceived(msg.sender, royalties);
    }

    function withdrawBalance() public onlyCreator {
        (bool success, ) = payable(creator).call{value: address(this).balance}("");
        require(success, "Withdrawal of contract balance failed");
    }
}
