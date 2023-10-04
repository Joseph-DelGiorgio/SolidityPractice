//GambleFI.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Casino {
    address public owner;
    uint public minimumBet;
    uint public totalBets;
    uint public totalPayouts;
    uint private secretNumber; // A secret number for random number generation

    struct Bet {
        uint betNumber;
        uint betAmount;
    }

    mapping(address => Bet) public playerBets;

    event BetPlaced(address indexed player, uint amount, uint[] betNumbers, uint luckyNumber, uint payout);
    event Payout(address indexed player, uint amount);
    event Withdraw(address indexed owner, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(uint _minimumBet) {
        owner = msg.sender;
        minimumBet = _minimumBet;
        secretNumber = uint(keccak256(abi.encodePacked(blockhash(block.number - 1))));
    }

    function setMinimumBet(uint _minimumBet) public onlyOwner {
        minimumBet = _minimumBet;
    }

    function withdrawFunds(uint _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
        emit Withdraw(owner, _amount);
    }

    function placeBet(uint[] memory _betNumbers) public payable {
        require(_betNumbers.length > 0, "Bet numbers required");
        require(msg.value >= minimumBet, "Bet amount too low");

        uint betAmount = msg.value;
        totalBets += betAmount;
        playerBets[msg.sender] = Bet({
            betNumber: _betNumbers[0],
            betAmount: betAmount
        });

        // Simulate a random number generation based on secret number and block properties
        uint luckyNumber = (uint(keccak256(abi.encodePacked(secretNumber, _betNumbers, block.timestamp))) % 100) + 1;

        uint payout = 0;
        for (uint i = 0; i < _betNumbers.length; i++) {
            if (_betNumbers[i] == luckyNumber) {
                // Payout is 10x the bet for a correct bet
                payout += betAmount * 10;
            }
        }

        totalPayouts += payout;

        if (payout > 0) {
            payable(msg.sender).transfer(payout);
        }

        emit BetPlaced(msg.sender, betAmount, _betNumbers, luckyNumber, payout);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayerBet() public view returns (uint, uint) {
        Bet memory playerBet = playerBets[msg.sender];
        return (playerBet.betNumber, playerBet.betAmount);
    }
}
