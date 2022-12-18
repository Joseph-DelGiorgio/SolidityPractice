pragma solidity ^0.8.0;

import "https://github.com/polygon-community/erc721/contracts/src/erc721.sol";

contract JoeBidenNFT is ERC721 {
    string public name = "Joe Biden NFT";
    string public symbol = "JBNFT";

    constructor() ERC721("Joe Biden NFT", "JBNFT") public {
        // Here you can initialize any state variables or perform any other setup tasks
    }

    function mint(
        address _to,
        string memory _imageUrl
    ) public {
        // Ensure that the caller has the correct permissions to mint a new NFT
        require(msg.sender == owner(), "Only the owner can mint new NFTs");

        // Increment the totalSupply to reflect the new NFT
        totalSupply++;

        // Create a new NFT and assign it to the specified address
        _mint(_to, totalSupply);

        // Store the image URL in the NFT's metadata
        _setTokenMetadata(totalSupply, _imageUrl);
    }
}

// To mint a new NFT, you would call the mint function with the address of the recipient and 
// the URL of the image you want to use for the NFT. 

JoeBidenNFT jbnft = JoeBidenNFT(<contract address>);
jbnft.mint(<recipient address>, "https://example.com/biden.jpg");
