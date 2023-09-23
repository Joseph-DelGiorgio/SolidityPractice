/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageAuction {
    address public storageOwner;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public minBidIncrement;
    uint256 public numStorageSlots;
    bool public auctionEnded;

    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime);
    event AuctionEnded(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == storageOwner, "Only owner can call this function");
        _;
    }

    modifier onlyBeforeAuctionEnd() {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        _;
    }

    constructor(uint256 biddingTime, uint256 minimumBidIncrement, uint256 storageSlots) {
        storageOwner = msg.sender;
        auctionEndTime = block.timestamp + biddingTime;
        minBidIncrement = minimumBidIncrement;
        numStorageSlots = storageSlots;
    }

    function bid() public payable onlyBeforeAuctionEnd {
        require(msg.value >= highestBid + minBidIncrement, "Bid must be higher than the current highest bid plus the minimum increment");

        if (highestBidder != address(0)) {
            // Refund the previous highest bidder
            payable(highestBidder).transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function extendAuction(uint256 newEndTime) public onlyOwner onlyBeforeAuctionEnd {
        require(newEndTime > auctionEndTime, "New end time must be after the current end time");

        auctionEndTime = newEndTime;
        emit AuctionExtended(newEndTime);
    }

    function endAuction() public onlyOwner onlyAfterAuctionEnd {
        require(!auctionEnded, "Auction already ended");

        auctionEnded = true;
        payable(storageOwner).transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdrawExcessBid() public onlyBeforeAuctionEnd {
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        require(msg.sender != storageOwner, "Storage owner cannot withdraw");
        require(msg.sender != address(0), "Invalid address");

        uint256 excessBid = msg.value;
        if (msg.value > highestBid + minBidIncrement) {
            excessBid = msg.value - highestBid - minBidIncrement;
        }

        payable(msg.sender).transfer(excessBid);
    }
}
