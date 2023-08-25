// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UniqueAuction {
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;
    
    // Mapping to keep track of bidders and their bids
    mapping(address => uint256) public bids;
    
    // Event emitted when the auction ends
    event AuctionEnded(address winner, uint256 winningBid);
    
    constructor(uint256 _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    modifier onlyBeforeEnd() {
        require(block.timestamp < auctionEndTime, "Auction has already ended");
        _;
    }
    
    modifier onlyAfterEnd() {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        _;
    }
    
    function placeBid() public payable onlyBeforeEnd {
        require(msg.value > highestBid, "Bid must be higher than the current highest bid");
        
        if (highestBid != 0) {
            // Refund the previous highest bidder
            bids[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    
    function endAuction() public onlyOwner onlyAfterEnd {
        require(!ended, "Auction has already ended");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        payable(owner).transfer(highestBid);
    }
}


//Version 2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExtendedAuction {
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;
    
    // Mapping to keep track of bidders and their bids
    mapping(address => uint256) public bids;
    
    // Event emitted when the auction ends
    event AuctionEnded(address winner, uint256 winningBid);
    
    constructor(uint256 _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    modifier onlyBeforeEnd() {
        require(block.timestamp < auctionEndTime, "Auction has already ended");
        _;
    }
    
    modifier onlyAfterEnd() {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        _;
    }
    
    function placeBid() public payable onlyBeforeEnd {
        require(msg.value > highestBid, "Bid must be higher than the current highest bid");
        
        if (highestBid != 0) {
            // Refund the previous highest bidder
            bids[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    
    function extendAuction(uint256 _extraTime) public onlyOwner onlyBeforeEnd {
        require(_extraTime > 0, "Extension time must be greater than zero");
        auctionEndTime += _extraTime;
    }
    
    function endAuction() public onlyOwner onlyAfterEnd {
        require(!ended, "Auction has already ended");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        payable(owner).transfer(highestBid);
    }
    
    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }
}
