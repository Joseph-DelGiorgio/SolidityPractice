//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtMarketplace is ERC721Enumerable, Ownable {
    uint256 public nextTokenId;
    uint256 public auctionDuration; // Auction duration in seconds

    mapping(uint256 => uint256) public tokenAuctionEnd;
    mapping(uint256 => address) public approvedAuctionBidder;
    mapping(uint256 => uint256) public highestBid;

    event ArtAuctionStarted(uint256 indexed tokenId, uint256 auctionEnd);
    event ArtAuctionBidPlaced(uint256 indexed tokenId, address bidder, uint256 bidAmount);

    constructor() ERC721("ArtMarketplace", "ART") {
        auctionDuration = 1 days; // Default to 1 day for auctions
    }

    function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
        auctionDuration = _auctionDuration;
    }

    function startAuction(uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(tokenAuctionEnd[tokenId] == 0, "Auction already started");

        uint256 auctionEnd = block.timestamp + auctionDuration;
        tokenAuctionEnd[tokenId] = auctionEnd;

        emit ArtAuctionStarted(tokenId, auctionEnd);
    }

    function placeBid(uint256 tokenId) external payable {
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp < tokenAuctionEnd[tokenId], "Auction ended");
        require(msg.value > highestBid[tokenId], "Bid amount is too low");

        address previousBidder = approvedAuctionBidder[tokenId];
        if (previousBidder != address(0)) {
            (bool returnSuccess, ) = previousBidder.call{value: highestBid[tokenId]}("");
            require(returnSuccess, "Failed to return previous bid");
        }

        highestBid[tokenId] = msg.value;
        approvedAuctionBidder[tokenId] = msg.sender;

        emit ArtAuctionBidPlaced(tokenId, msg.sender, msg.value);
    }

    function getHighestBidder(uint256 tokenId) external view returns (address) {
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp >= tokenAuctionEnd[tokenId], "Auction not ended yet");

        return approvedAuctionBidder[tokenId];
    }

    function claimArt(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp >= tokenAuctionEnd[tokenId], "Auction not ended yet");
        require(approvedAuctionBidder[tokenId] == msg.sender, "Not the highest bidder");

        _transfer(ownerOf(tokenId), msg.sender, tokenId);

        // Reset auction data
        tokenAuctionEnd[tokenId] = 0;
        highestBid[tokenId] = 0;
        approvedAuctionBidder[tokenId] = address(0);
    }

    function mint() external {
        require(nextTokenId < 10000, "Token limit exceeded");
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }

       function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }


    function emergencyWithdraw(uint256 tokenId) external onlyOwner {
        require(tokenAuctionEnd[tokenId] > 0, "Auction not started");
        require(block.timestamp >= tokenAuctionEnd[tokenId], "Auction not ended yet");

        address highestBidder = approvedAuctionBidder[tokenId];
        require(highestBidder != address(0), "No approved bidder");

        // Transfer the highest bid to the highest bidder
        (bool success, ) = highestBidder.call{value: highestBid[tokenId]}("");
        require(success, "Transfer failed");

        // Reset auction data
        tokenAuctionEnd[tokenId] = 0;
        highestBid[tokenId] = 0;
        approvedAuctionBidder[tokenId] = address(0);
    }

    function emergencyTokenTransfer(address to, uint256 tokenId) external onlyOwner {
        _transfer(owner(), to, tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {}

    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://put api.example here"; //put api link example here
    }

      modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    event ArtAuctionEnded(uint256 indexed tokenId, address winner, uint256 winningBid);



    // Add other helper functions, events, etc.
}

