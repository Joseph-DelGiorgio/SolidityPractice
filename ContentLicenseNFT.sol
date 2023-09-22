//t
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContentLicense is ERC721Enumerable, Ownable {
    string private _baseTokenURI;

    uint256 private _nextTokenId = 1;
    uint256 private _licensePrice = 1 ether;

    mapping(uint256 => string) private _tokenContent;

    event ContentLicensed(uint256 indexed tokenId, address indexed licensee);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setLicensePrice(uint256 price) external onlyOwner {
        _licensePrice = price;
    }

    function getLicensePrice() external view returns (uint256) {
        return _licensePrice;
    }

    function purchaseLicense(uint256 tokenId) external payable {
        require(tokenId > 0 && tokenId < _nextTokenId, "Invalid token ID");
        require(ownerOf(tokenId) == address(this), "Token not available for license");
        require(msg.value >= _licensePrice, "Insufficient payment for license");

        _safeTransfer(owner(), msg.sender, tokenId, "");
        emit ContentLicensed(tokenId, msg.sender);
    }

    function createLicense(string memory contentURI) external onlyOwner {
        _mint(owner(), _nextTokenId);
        _tokenContent[_nextTokenId] = contentURI;
        _nextTokenId++;
    }

    function getTokenContent(uint256 tokenId) external view returns (string memory) {
        require(tokenId > 0 && tokenId < _nextTokenId, "Invalid token ID");
        return _tokenContent[tokenId];
    }
}
