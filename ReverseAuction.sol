// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title ReverseAuction
 * @dev This contract implements a reverse auction where suppliers bid lower prices for a contract, and the lowest bid wins.
 */
contract ReverseAuction {
    // Structure to hold supplier details
    struct Supplier {
        address supplierAddress;
        uint256 bidAmount;
    }

    // Auction parameters
    address public buyer;
    uint256 public startPrice;
    uint256 public auctionEndTime;
    bool public auctionEnded;

    // List of suppliers and their bids
    Supplier[] public suppliers;

    // Events to notify changes
    event NewBid(address indexed supplier, uint256 bidAmount);
    event AuctionEnded(address winner, uint256 winningBid);

    /**
     * @dev Initializes the contract with the auction parameters.
     * @param _startPrice The starting price of the auction.
     * @param _biddingTime The duration of the auction in seconds.
     */
    constructor(uint256 _startPrice, uint256 _biddingTime) {
        buyer = msg.sender;
        startPrice = _startPrice;
        auctionEndTime = block.timestamp + _biddingTime;
        auctionEnded = false;
    }

    /**
     * @dev Modifier to ensure the auction is still ongoing.
     */
    modifier onlyBeforeEnd() {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        _;
    }

    /**
     * @dev Allows suppliers to submit bids. The bid amount must be lower than the starting price and greater than zero.
     */
    function bid() external payable onlyBeforeEnd {
        require(msg.value < startPrice, "Bid amount must be lower than start price.");
        require(msg.value > 0, "Bid amount must be greater than zero.");

        suppliers.push(Supplier({
            supplierAddress: msg.sender,
            bidAmount: msg.value
        }));

        emit NewBid(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction, determines the winner, and handles payments.
     * Can only be called by the buyer after the auction ends.
     */
    function endAuction() external {
        require(msg.sender == buyer, "Only the buyer can end the auction.");
        require(block.timestamp >= auctionEndTime, "Auction is still ongoing.");
        require(!auctionEnded, "Auction has already ended.");

        auctionEnded = true;

        // Determine the winner (supplier with the lowest bid)
        Supplier memory winner = suppliers[0];
        for (uint256 i = 1; i < suppliers.length; i++) {
            if (suppliers[i].bidAmount < winner.bidAmount) {
                winner = suppliers[i];
            }
        }

        // Refund all bids except the winning bid
        for (uint256 i = 0; i < suppliers.length; i++) {
            if (suppliers[i].supplierAddress != winner.supplierAddress) {
                payable(suppliers[i].supplierAddress).transfer(suppliers[i].bidAmount);
            }
        }

        // Transfer the winning bid amount to the buyer
        payable(buyer).transfer(winner.bidAmount);

        emit AuctionEnded(winner.supplierAddress, winner.bidAmount);
    }
}

