// the requestPrices() function is used to send a request to the Chainlink oracle to retrieve the current prices of 
// Bitcoin, Ethereum, and Polygon. The fulfill() function is called by the oracle when it returns the prices, 
// and it updates the contract's variables bitcoinPrice, ethereumPrice, and polygonPrice with the received values.
// You will need to replace the placeholder values for the oracle address and job ID with the actual values for your oracle and job. 
// You may also need to adjust the request payload and the fulfill() function to match the format of the data returned by your oracle.


pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

// The address of the Chainlink oracle
address public oracle;

// The job ID of the Chainlink oracle
bytes32 public jobId;

// The current prices of Bitcoin, Ethereum, and Polygon
uint public bitcoinPrice;
uint public ethereumPrice;
uint public polygonPrice;

constructor() public {
    // Set the oracle and job ID
    oracle = 0x0123456789abcdef0123456789abcdef01234567;
    jobId = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01;
}

// Function to request the current prices from the oracle
function requestPrices() public {
    Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    req.add("bitcoin", "BTC");
    req.add("ethereum", "ETH");
    req.add("polygon", "MATIC");
    sendChainlinkRequestTo(oracle, req, oracle);
}

// Function to handle the response from the oracle
function fulfill(bytes32 _requestId, uint _bitcoinPrice, uint _ethereumPrice, uint _polygonPrice) public {
    require(_requestId == jobId, "Invalid request ID");
    bitcoinPrice = _bitcoinPrice;
    ethereumPrice = _ethereumPrice;
    polygonPrice = _polygonPrice;
}
