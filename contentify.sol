// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Contentify is Ownable {
    struct Content {
        address creator;
        string contentHash;
        uint256 price; // in platform's native token
        uint256 totalPurchases;
        uint256 purchaseLimit;
    }

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;

    IERC20 public platformToken;

    event ContentUploaded(uint256 indexed contentId, address indexed creator, string contentHash, uint256 price, uint256 purchaseLimit);
    event ContentPurchased(uint256 indexed contentId, address indexed buyer);

    constructor(address _platformTokenAddress) {
        platformToken = IERC20(_platformTokenAddress);
    }

    function uploadContent(string memory _contentHash, uint256 _price, uint256 _purchaseLimit) external {
        require(_price > 0, "Price must be greater than 0");

        uint256 newContentId = contentCount;
        contents[newContentId] = Content({
            creator: msg.sender,
            contentHash: _contentHash,
            price: _price,
            totalPurchases: 0,
            purchaseLimit: _purchaseLimit
        });

        contentCount++;

        emit ContentUploaded(newContentId, msg.sender, _contentHash, _price, _purchaseLimit);
    }

    function purchaseContent(uint256 _contentId) external {
        Content storage content = contents[_contentId];
        require(content.creator != address(0), "Content not found");
        require(content.totalPurchases < content.purchaseLimit || content.purchaseLimit == 0, "Purchase limit reached");
        require(platformToken.balanceOf(msg.sender) >= content.price, "Insufficient balance");

        platformToken.transferFrom(msg.sender, content.creator, content.price);

        content.totalPurchases++;

        emit ContentPurchased(_contentId, msg.sender);
    }

    function getContentDetails(uint256 _contentId) external view returns (address, string memory, uint256, uint256, uint256) {
        Content storage content = contents[_contentId];
        return (content.creator, content.contentHash, content.price, content.totalPurchases, content.purchaseLimit);
    }
}
