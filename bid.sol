pragma solidity ^0.8.0;

contract Auction {
    // The address of the current highest bidder
    address public highestBidder;

    // The current highest bid
    uint public highestBid;

    // The auction end time
    uint public auctionEnd;

    // Event for when a new highest bid is placed
    event NewBid(address bidder, uint bid);

    // Function to place a bid on the auction
    function bid(uint _bid) public payable {
        require(msg.value >= _bid, "Bid must be equal to or greater than the value sent with the transaction");
        require(_bid > highestBid, "Bid must be higher than the current highest bid");
        require(now <= auctionEnd, "Auction has ended");

        highestBidder = msg.sender;
        highestBid = _bid;

        emit NewBid(highestBidder, highestBid);
    }

    // Function to end the auction and transfer the highest bid amount to the contract owner
    function endAuction() public {
        require(msg.sender == highestBidder, "Only the highest bidder can end the auction");
        require(now > auctionEnd, "Auction has not ended");

        msg.sender.transfer(highestBid);
    }
}
