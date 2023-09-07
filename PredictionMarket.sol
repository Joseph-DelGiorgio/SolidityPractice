// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PredictionMarket is Ownable, Pausable {
    struct Market {
        string question;
        uint256 endTime;
        bool finalized;
        Outcome[] outcomes;
    }

    struct Outcome {
        string description;
        uint256 probability;
        uint256 totalStaked;
        bool finalOutcome;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;

    mapping(address => uint256[]) public userMarkets;

    event MarketCreated(uint256 indexed marketId, string question, uint256 endTime);
    event OutcomeCreated(uint256 indexed marketId, uint256 outcomeId, string description, uint256 probability);
    event BetPlaced(uint256 indexed marketId, uint256 indexed outcomeId, address indexed user, uint256 amount);
    event MarketFinalized(uint256 indexed marketId, uint256 finalOutcomeId, string description);
    event Withdrawn(uint256 indexed marketId, uint256 indexed outcomeId, address indexed user, uint256 amount);

    IERC20 public token; // The ERC20 token used for betting

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    modifier onlyContributor(uint256 _marketId) {
        require(isContributor(_marketId, msg.sender), "You are not a contributor to this market");
        _;
    }

    modifier onlyOwnerOrPaused(uint256 _marketId) {
        require(owner() == msg.sender || paused(), "Only the owner or when paused");
        _;
    }

    function createMarket(string memory _question, uint256 _endTime) external whenNotPaused {
        marketCount++;
        uint256 marketId = marketCount;
        markets[marketId] = Market({
            question: _question,
            endTime: _endTime,
            finalized: false,
            outcomes: new Outcome[](0)
        });

        emit MarketCreated(marketId, _question, _endTime);
    }

    function createOutcome(uint256 _marketId, string memory _description, uint256 _probability) external onlyOwnerOrPaused(_marketId) {
        require(_marketId <= marketCount, "Market does not exist");
        Market storage market = markets[_marketId];
        require(!market.finalized, "Market already finalized");

        uint256 outcomeId = market.outcomes.length;
        market.outcomes.push(Outcome({
            description: _description,
            probability: _probability,
            totalStaked: 0,
            finalOutcome: false
        }));

        emit OutcomeCreated(_marketId, outcomeId, _description, _probability);
    }

    function placeBet(uint256 _marketId, uint256 _outcomeId, uint256 _amount) external whenNotPaused {
        require(_marketId <= marketCount, "Market does not exist");
        require(!_isMarketExpired(_marketId), "Market has expired");
        Market storage market = markets[_marketId];
        Outcome storage outcome = market.outcomes[_outcomeId];
        require(!outcome.finalOutcome, "Outcome is finalized");

        token.transferFrom(msg.sender, address(this), _amount);
        outcome.totalStaked += _amount;

        userMarkets[msg.sender].push(_marketId);

        emit BetPlaced(_marketId, _outcomeId, msg.sender, _amount);
    }

    function finalizeMarket(uint256 _marketId, uint256 _finalOutcomeId, string memory _description) external onlyOwnerOrPaused(_marketId) {
        require(_marketId <= marketCount, "Market does not exist");
        require(!_isMarketExpired(_marketId), "Market has expired");
        Market storage market = markets[_marketId];
        Outcome storage finalOutcome = market.outcomes[_finalOutcomeId];
        require(!finalOutcome.finalOutcome, "Outcome is already finalized");

        for (uint256 i = 0; i < market.outcomes.length; i++) {
            if (i == _finalOutcomeId) {
                market.outcomes[i].finalOutcome = true;
            } else {
                market.outcomes[i].finalOutcome = false;
            }
        }

        market.finalized = true;

        emit MarketFinalized(_marketId, _finalOutcomeId, _description);
    }

    function withdrawWinnings(uint256 _marketId, uint256 _outcomeId) external whenNotPaused {
        require(_marketId <= marketCount, "Market does not exist");
        Market storage market = markets[_marketId];
        Outcome storage outcome = market.outcomes[_outcomeId];
        require(outcome.finalOutcome, "Outcome is not finalized");
        uint256 userBet = _getUserBet(_marketId, _outcomeId, msg.sender);
        require(userBet > 0, "No winnings to withdraw");

        uint256 winnings = (userBet * market.outcomes[_outcomeId].totalStaked) / market.outcomes[_outcomeId].totalStaked;
        token.transfer(msg.sender, winnings);

        emit Withdrawn(_marketId, _outcomeId, msg.sender, winnings);
    }

    function _getUserBet(uint256 _marketId, uint256 _outcomeId, address _user) internal view returns (uint256) {
        Market storage market = markets[_marketId];
        return (market.outcomes[_outcomeId].totalStaked * token.balanceOf(_user)) / token.totalSupply();
    }

    function getUserMarkets(address _user) external view returns (uint256[] memory) {
        return userMarkets[_user];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _isMarketExpired(uint256 _marketId) internal view returns (bool) {
        return block.timestamp >= markets[_marketId].endTime;
    }
}
