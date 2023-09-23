/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageAuction {
    address public storageOwner;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public auctionEnded;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == storageOwner, "Only owner can call this function");
        _;
    }

    modifier onlyBeforeAuctionEnd() {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        _;
    }

    modifier onlyAfterAuctionEnd() {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        _;
    }

    constructor(uint256 biddingTime) {
        storageOwner = msg.sender;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() public payable onlyBeforeAuctionEnd {
        require(msg.value > highestBid, "Bid must be higher than the current highest bid");

        if (highestBidder != address(0)) {
            // Refund the previous highest bidder
            payable(highestBidder).transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function endAuction() public onlyOwner onlyAfterAuctionEnd {
        require(!auctionEnded, "Auction already ended");

        auctionEnded = true;
        payable(storageOwner).transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }
}
