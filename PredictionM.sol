pragma solidity ^0.8.0;

contract PredictionMarket {
    // Events
    event MarketCreated(address indexed creator, uint indexed eventId, string title, uint indexed endTime, uint indexed payout);
    event SharesBought(address indexed buyer, uint indexed eventId, uint indexed outcome, uint indexed amount);
    event DisputeStarted(uint indexed eventId, uint indexed outcome);
    event DisputeResolved(uint indexed eventId, uint indexed outcome);

    // Structs
    struct Market {
        address creator;
        string title;
        uint endTime;
        uint payout;
        bool resolved;
    }

    struct Share {
        uint eventId;
        uint outcome;
        uint amount;
    }

    // State variables
    Market[] public markets;
    mapping (uint => mapping (uint => uint)) public shares;
    mapping (address => uint) public balances;

    // Functions
    function createMarket(string memory title, uint endTime, uint payout) public {
        uint eventId = markets.length;
        markets.push(Market(msg.sender, title, endTime, payout, false));
        emit MarketCreated(msg.sender, eventId, title, endTime, payout);
    }

    function buyShares(uint eventId, uint outcome, uint amount) public payable {
        Market memory market = markets[eventId];
        require(block.timestamp < market.endTime, "Market has ended.");
        require(!market.resolved, "Market has been resolved.");
        require(msg.value == amount, "Amount doesn't match Ether sent.");

        // Create shares for the buyer
        shares[eventId][outcome] += amount;
        balances[msg.sender] += amount;

        emit SharesBought(msg.sender, eventId, outcome, amount);
    }

    function startDispute(uint eventId, uint outcome) public {
        Market memory market = markets[eventId];
        require(block.timestamp >= market.endTime, "Market hasn't ended yet.");
        require(!market.resolved, "Market has already been resolved.");
        require(shares[eventId][outcome] > 0, "No shares held for this outcome.");

        market.resolved = true;
        markets[eventId] = market;

        emit DisputeStarted(eventId, outcome);
    }

    function resolveDispute(uint eventId, uint outcome) public {
        require(shares[eventId][outcome] > 0, "No shares held for this outcome.");
        uint payoutPerShare = markets[eventId].payout / shares[eventId][outcome];
        for (uint i = 0; i < markets.length; i++) {
            uint shareAmount = shares[eventId][i];
            balances[msg.sender] += shareAmount * payoutPerShare;
        }

        emit DisputeResolved(eventId, outcome);
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw.");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
