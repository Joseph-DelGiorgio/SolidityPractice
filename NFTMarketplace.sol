// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC721 standard interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable, IERC721Receiver {
    // Declare variables
    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool isSold;
    }

    IERC721 public nft;
    uint256 public fee; // Fee charged on every transaction
    uint256 public auctionId = 0;
    mapping (uint256 => Auction) public auctions;

    // Events
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 price);
    event AuctionCancelled(uint256 auctionId);
    event AuctionSold(uint256 auctionId, address buyer, uint256 price);

    constructor(IERC721 _nft, uint256 _fee) {
        nft = _nft;
        fee = _fee;
    }

    // Functions
    function createAuction(uint256 tokenId, uint256 price) public {
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(price > 0, "Price cannot be zero");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        auctions[auctionId] = Auction(msg.sender, tokenId, price, false);
        emit AuctionCreated(auctionId, tokenId, msg.sender, price);

        auctionId++;
    }

    function cancelAuction(uint256 _auctionId) public {
        Auction memory auction = auctions[_auctionId];

        require(auction.seller == msg.sender, "You are not the seller of this auction");

        nft.safeTransferFrom(address(this), msg.sender, auction.tokenId);

        delete auctions[_auctionId];
        emit AuctionCancelled(_auctionId);
    }

    function buy(uint256 _auctionId) public payable {
        Auction memory auction = auctions[_auctionId];

        require(!auction.isSold, "This auction is already sold");
        require(msg.value >= auction.price, "Not enough Ether");

        // Send fees to owner of the marketplace
        uint256 fees = (msg.value * fee) / 100;
        payable(owner()).transfer(fees);

        // Send remaining balance to seller
        payable(auction.seller).transfer(msg.value - fees);

        // Transfer NFT to buyer
        nft.safeTransferFrom(address(this), msg.sender, auction.tokenId);

        // Update auction
        auction.isSold = true;
        auctions[_auctionId] = auction;

        emit AuctionSold(_auctionId, msg.sender, msg.value);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
