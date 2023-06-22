// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract WeatherContract is ChainlinkClient {
    string public weather;
    uint256 public temperature;

    event WeatherUpdated(string newWeather, uint256 newTemperature);

    constructor(address _linkTokenAddress, address _oracleAddress, bytes32 _jobId) {
        setChainlinkToken(_linkTokenAddress);
        setChainlinkOracle(_oracleAddress);
        setChainlinkJobId(_jobId);
    }

    function updateWeather() external {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        // Set additional parameters for the Chainlink request
        request.add("q", "London, UK");

        // Send the Chainlink request
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _temperature) public recordChainlinkFulfillment(_requestId) {
        weather = getWeatherByTemperature(_temperature);
        temperature = _temperature;
        emit WeatherUpdated(weather, temperature);
    }

    function getWeatherByTemperature(uint256 _temperature) internal pure returns (string memory) {
        if (_temperature > 25) {
            return "Hot";
        } else if (_temperature > 15) {
            return "Warm";
        } else if (_temperature > 5) {
            return "Cool";
        } else {
            return "Cold";
        }
    }
}
