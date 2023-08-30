// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedCrowdfunding {
    address public owner;
    uint256 public campaignCount;
    uint256 public minContribution;
    uint256 public deadline;

    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 totalFunds;
        mapping(address => uint256) contributions;
    }

    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 campaignId, string title, uint256 goalAmount);
    event FundsContributed(uint256 campaignId, address contributor, uint256 amount);
    event CampaignFinished(uint256 campaignId, uint256 totalFunds);

    constructor(uint256 _minContribution, uint256 _deadline) {
        owner = msg.sender;
        campaignCount = 0;
        minContribution = _minContribution;
        deadline = block.timestamp + _deadline;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Campaign does not exist");
        _;
    }

    modifier campaignNotExpired(uint256 _campaignId) {
        require(block.timestamp <= deadline, "Campaign has expired");
        _;
    }

    function createCampaign(string memory _title, string memory _description, uint256 _goalAmount) public {
        campaignCount++;
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            totalFunds: 0
        });
        emit CampaignCreated(campaignCount, _title, _goalAmount);
    }

    function contributeFunds(uint256 _campaignId) public payable campaignExists(_campaignId) campaignNotExpired(_campaignId) {
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        
        Campaign storage campaign = campaigns[_campaignId];
        campaign.contributions[msg.sender] += msg.value;
        campaign.totalFunds += msg.value;
        emit FundsContributed(_campaignId, msg.sender, msg.value);
    }

    function finishCampaign(uint256 _campaignId) public onlyOwner campaignExists(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > deadline, "Campaign has not yet expired");

        if (campaign.totalFunds >= campaign.goalAmount) {
            payable(campaign.creator).transfer(campaign.totalFunds);
        }
        
        emit CampaignFinished(_campaignId, campaign.totalFunds);
    }
}
