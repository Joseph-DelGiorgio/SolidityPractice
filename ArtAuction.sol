//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtMarketplace is ERC721Enumerable, Ownable {
    uint256 public nextTokenId;
    uint256 public auctionDuration;  // Auction duration in seconds

    mapping(uint256 => uint256) public tokenPrice;  // Token ID to Price
    mapping(uint256 => uint256) public tokenAuctionEnd;  // Token ID to Auction End Time

    event ArtTokenListed(uint256 indexed tokenId, uint256 price);
    event ArtTokenDelisted(uint256 indexed tokenId);
    event ArtTokenPurchased(uint256 indexed tokenId, address buyer, uint256 price);
    event ArtTokenAuctionStarted(uint256 indexed tokenId, uint256 endTime);
    event ArtTokenAuctionEnded(uint256 indexed tokenId, address winner, uint256 price);

    constructor() ERC721("ArtMarketplace", "ART") {
        nextTokenId = 1;
        auctionDuration = 7 days;  // Initial auction duration set to 7 days
    }

    function listArtForSale(uint256 tokenId, uint256 price) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
        require(price > 0, "Price must be greater than 0");

        tokenPrice[tokenId] = price;
        emit ArtTokenListed(tokenId, price);
    }

    function delistArt(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");

        tokenPrice[tokenId] = 0;
        emit ArtTokenDelisted(tokenId);
    }

    function purchaseArt(uint256 tokenId) external payable {
        uint256 price = tokenPrice[tokenId];
        require(price > 0, "Art not for sale");
        require(msg.value >= price, "Insufficient funds");

        address seller = ownerOf(tokenId);

        _transfer(seller, msg.sender, tokenId);
        tokenPrice[tokenId] = 0;  // Remove listing

        (bool success, ) = seller.call{value: price}("");  // Send funds to the seller
        require(success, "Payment to seller failed");

        emit ArtTokenPurchased(tokenId, msg.sender, price);
    }

    function startAuction(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");

        uint256 endTime = block.timestamp + auctionDuration;
        tokenAuctionEnd[tokenId] = endTime;

        emit ArtTokenAuctionStarted(tokenId, endTime);
    }

    function endAuction(uint256 tokenId) external {
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp >= tokenAuctionEnd[tokenId], "Auction not ended yet");

        address winner = highestBidder(tokenId);
        require(winner != address(0), "No bids");

        uint256 price = msg.value;

        // Transfer the NFT to the winner
        _transfer(ownerOf(tokenId), winner, tokenId);

        // Transfer the bid amount to the seller
        (bool success, ) = ownerOf(tokenId).call{value: price}("");
        require(success, "Payment to seller failed");

        // Reset auction data
        tokenAuctionEnd[tokenId] = 0;

        emit ArtTokenAuctionEnded(tokenId, winner, price);
    }

    function highestBidder(uint256 tokenId) public view returns (address) {
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp >= tokenAuctionEnd[tokenId], "Auction not ended yet");

        uint256 highestBid = 0;
        address highestBidderAddress;

        // Find the highest bidder
        for (uint256 i = 0; i < balanceOf(address(this)); i++) {
            address bidder = ownerOf(tokenByIndex(tokenId));
            uint256 bid = msg.value;

            if (bid > highestBid) {
                highestBid = bid;
                highestBidderAddress = bidder;
            }
        }

        return highestBidderAddress;
    }

    // Override functions to handle auction end times
    function _baseURI() internal view virtual override returns (string memory) {}
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {}

    // ... (other helper functions, events, etc.)
}

