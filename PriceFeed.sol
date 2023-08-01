// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PriceFeedContract {
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    uint256 private decimals;
    AggregatorV3Interface internal priceFeed;

    constructor(address _oracle, bytes32 _jobId, uint256 _fee, address _tokenAddress) {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        decimals = IERC20Metadata(_tokenAddress).decimals(); // Assuming the token being used has 18 decimals
        priceFeed = AggregatorV3Interface(_tokenAddress); // The address of the Chainlink Price Feed for the token
    }

    function getLatestPrice() external view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getPrice() external view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 tokenDecimals = 10**decimals;
        return uint256(price) * tokenDecimals;
    }

    // Function to set the Chainlink oracle address (only callable by the contract owner)
    function setOracle(address _newOracle) external onlyOwner {
        oracle = _newOracle;
    }

    // Function to set the Chainlink job ID (only callable by the contract owner)
    function setJobId(bytes32 _newJobId) external onlyOwner {
        jobId = _newJobId;
    }

    // Function to set the Chainlink fee (only callable by the contract owner)
    function setFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    // Modifier to restrict access to certain functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    // Function to fetch the price of any ERC20 token by passing its address
    function getTokenPrice(address _tokenAddress) external view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_tokenAddress).latestRoundData();
        uint256 tokenDecimals = 10**IERC20Metadata(_tokenAddress).decimals();
        return uint256(price) * tokenDecimals;
    }

    // Function to fetch the price of multiple ERC20 tokens by passing an array of addresses
    function getMultipleTokenPrices(address[] calldata _tokenAddresses) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](_tokenAddresses.length);
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            (, int256 price, , , ) = AggregatorV3Interface(_tokenAddresses[i]).latestRoundData();
            uint256 tokenDecimals = 10**IERC20Metadata(_tokenAddresses[i]).decimals();
            prices[i] = uint256(price) * tokenDecimals;
        }
        return prices;
    }

    // Add additional functions and logic as needed for your use case
}
