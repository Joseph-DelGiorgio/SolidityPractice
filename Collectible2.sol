pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract CollectibleToken is ERC721 {

    using SafeMath for uint256;

    string public name = "My Collectible Token";
    string public symbol = "MCT";
    string public version = "1.0";
    uint256 public totalSupply;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private owners;

    // Mapping from token ID to metadata URI
    mapping (uint256 => string) private metadataURI;

    // Event for when a token is minted
    event TokenMinted(uint256 tokenId, address owner, string metadataURI);

    // Event for when a token is transferred
    event TokenTransferred(uint256 tokenId, address from, address to);

    constructor() public {
        totalSupply = 0;
    }

    // Function to mint a new token
    function mint(address _owner, string memory _metadataURI) public {
        require(msg.sender == address(this), "Only the contract owner can mint new tokens");

        // Increment the total supply and get the new token ID
        totalSupply = totalSupply.add(1);
        uint256 newTokenId = totalSupply;

        // Assign the token to the owner and set the metadata URI
        owners[newTokenId] = _owner;
        metadataURI[newTokenId] = _metadataURI;

        // Emit the TokenMinted event
        emit TokenMinted(newTokenId, _owner, _metadataURI);

        // Transfer the token to the owner
        _transfer(address(0), _owner, newTokenId);
    }

    // Overriding the transferFrom function to emit an event when a token is transferred
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_from != address(0), "Cannot transfer a token from the zero address");
        require(_to != address(0), "Cannot transfer a token to the zero address");
        require(_from == owners[_tokenId], "Token is not owned by the sender");

        // Remove the token from the sender and add it to the recipient
        owners[_tokenId] = _to;

        // Emit the TokenTransferred event
        emit TokenTransferred(_tokenId, _from, _to);

        // Transfer the token to the recipient
        _transfer(_from, _to, _tokenId);
    }

    // Overriding the ownerOf function to return the owner of a token
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = owners[_tokenId];
    }

    // Overriding the tokenURI function to return the metadata URI of a token
    function tokenURI(uint256 _tokenId) public view returns (string memory){
    return metadataURI[_tokenId];
    }

}

