// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Contentify is Ownable {
    struct Content {
        address creator;
        string contentHash;
        uint256 price; // in platform's native token
    }

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;

    IERC20 public platformToken;

    event ContentUploaded(uint256 indexed contentId, address indexed creator, string contentHash, uint256 price);

    constructor(address _platformTokenAddress) {
        platformToken = IERC20(_platformTokenAddress);
    }

    function uploadContent(string memory _contentHash, uint256 _price) external {
        require(_price > 0, "Price must be greater than 0");

        uint256 newContentId = contentCount;
        contents[newContentId] = Content({
            creator: msg.sender,
            contentHash: _contentHash,
            price: _price
        });

        contentCount++;

        emit ContentUploaded(newContentId, msg.sender, _contentHash, _price);
    }

    function purchaseContent(uint256 _contentId) external {
        Content storage content = contents[_contentId];
        require(content.creator != address(0), "Content not found");
        require(platformToken.balanceOf(msg.sender) >= content.price, "Insufficient balance");

        platformToken.transferFrom(msg.sender, content.creator, content.price);

        // Platform takes a small fee (10% in this example)
        uint256 platformFee = (content.price * 10) / 100;
        platformToken.transfer(owner(), platformFee);

        // Remaining amount goes to the content creator
        uint256 creatorAmount = content.price - platformFee;
        platformToken.transfer(content.creator, creatorAmount);
    }
}
