// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract RandomNumberContract is ChainlinkClient {
    uint256 public randomNumber;

    event RandomNumberGenerated(uint256 number);

    constructor(address _linkTokenAddress, address _oracleAddress, bytes32 _jobId) {
        setChainlinkToken(_linkTokenAddress);
        setChainlinkOracle(_oracleAddress);
        setChainlinkJobId(_jobId);
    }

    function generateRandomNumber() external {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        // Set additional parameters for the Chainlink request
        request.add("get", "https://api.chainlinkrandomnumber.com/random");

        // Send the Chainlink request
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _randomNumber) public recordChainlinkFulfillment(_requestId) {
        randomNumber = _randomNumber;
        emit RandomNumberGenerated(randomNumber);
    }
}
