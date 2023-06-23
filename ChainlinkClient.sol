// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract PriceFeedContract is ChainlinkClient {
    uint256 public currentPrice;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    event PriceUpdated(uint256 newPrice);

    constructor(address _linkTokenAddress, address _oracleAddress, bytes32 _jobId, uint256 _fee) {
        setChainlinkToken(_linkTokenAddress);
        oracle = _oracleAddress;
        jobId = _jobId;
        fee = _fee;
    }

    function updatePrice() external {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        request.add("get", "https://api.example.com/price");

        string[] memory path = new string[](1);
        path[0] = "price";
        request.addStringArray("path", path);

        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        currentPrice = _price;
        emit PriceUpdated(currentPrice);
    }
}
