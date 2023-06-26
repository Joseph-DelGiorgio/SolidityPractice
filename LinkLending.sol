// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract ChainlinkLending {
    AggregatorV3Interface private priceFeed;
    LinkTokenInterface private linkToken;

    struct Loan {
        address borrower;
        uint256 amount;
        uint256 collateral;
        bool active;
    }

    mapping(address => Loan) public loans;

    constructor(address _priceFeedAddress, address _linkTokenAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        linkToken = LinkTokenInterface(_linkTokenAddress);
    }

    function requestLoan(uint256 _amount, uint256 _collateral) external {
        require(loans[msg.sender].active == false, "You already have an active loan.");

        int256 currentPrice = getCurrentPrice();
        uint256 collateralValue = _collateral * uint256(currentPrice);

        require(_amount <= collateralValue, "Insufficient collateral.");

        loans[msg.sender] = Loan({
            borrower: msg.sender,
            amount: _amount,
            collateral: _collateral,
            active: true
        });

        // Transfer loan amount to borrower's address
        linkToken.transfer(msg.sender, _amount);
    }

    function repayLoan() external {
        require(loans[msg.sender].active == true, "No active loan found.");

        uint256 loanAmount = loans[msg.sender].amount;
        loans[msg.sender].active = false;

        // Transfer loan amount back to the contract
        linkToken.transferFrom(msg.sender, address(this), loanAmount);
    }

    function getCurrentPrice() internal view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
