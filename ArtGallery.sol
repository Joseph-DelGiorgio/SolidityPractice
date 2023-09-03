// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DecentralizedArtGallery is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // Structure for each artwork
    struct Artwork {
        address artist;
        uint256 price;
        uint256 royaltyPercentage;
    }

    // Counter for artwork IDs
    Counters.Counter private _artworkIdCounter;

    // Mapping from artwork ID to artwork details
    mapping(uint256 => Artwork) public artworks;

    // Mapping from token ID to its auction status
    mapping(uint256 => bool) public isAuctionActive;

    // Events
    event ArtworkMinted(uint256 indexed tokenId, address indexed artist, uint256 price, uint256 royaltyPercentage);
    event ArtworkSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ArtworkResold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    constructor() ERC721("DecentralizedArtGallery", "DAG") {}

    // Mint a new artwork
    function mintArtwork(uint256 _price, uint256 _royaltyPercentage) external {
        require(_price > 0, "Price must be greater than 0");
        require(_royaltyPercentage <= 100, "Royalty percentage must be 100 or less");

        _artworkIdCounter.increment();
        uint256 tokenId = _artworkIdCounter.current();
        _mint(msg.sender, tokenId);

        artworks[tokenId] = Artwork({
            artist: msg.sender,
            price: _price,
            royaltyPercentage: _royaltyPercentage
        });

        emit ArtworkMinted(tokenId, msg.sender, _price, _royaltyPercentage);
    }

    // Purchase an artwork
    function purchaseArtwork(uint256 _tokenId) external payable {
        Artwork storage artwork = artworks[_tokenId];
        require(_exists(_tokenId), "Artwork does not exist");
        require(!isAuctionActive[_tokenId], "Artwork is in auction");
        require(msg.value >= artwork.price, "Insufficient funds");

        address artist = artwork.artist;
        uint256 royalty = (msg.value * artwork.royaltyPercentage) / 100;
        uint256 remainingBalance = msg.value - royalty;

        payable(artist).transfer(remainingBalance);
        payable(owner()).transfer(royalty);

        _transfer(artist, msg.sender, _tokenId);
        emit ArtworkSold(_tokenId, msg.sender, msg.value);
    }

    // Resell an artwork
    function resellArtwork(uint256 _tokenId, uint256 _price) external {
        require(_exists(_tokenId), "Artwork does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You do not own this artwork");

        artworks[_tokenId].price = _price;
        emit ArtworkResold(_tokenId, msg.sender, address(0), _price);
    }

    // Enable or disable auction for an artwork
    function toggleAuction(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Artwork does not exist");
        isAuctionActive[_tokenId] = !isAuctionActive[_tokenId];
    }
}
