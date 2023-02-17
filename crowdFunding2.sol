pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        uint goal;
        uint raised;
        uint deadline;
        bool complete;
        mapping(address => uint) contributions;
        uint numContributions;
    }

    mapping(uint => Campaign) public campaigns;
    uint public numCampaigns;

    event CampaignCreated(uint campaignId, address creator, uint goal, uint deadline);
    event ContributionMade(uint campaignId, address contributor, uint amount);
    event CampaignCompleted(uint campaignId, bool success);

    function createCampaign(uint goal, uint durationDays) public {
        require(goal > 0, "Goal must be greater than zero");
        require(durationDays > 0, "Duration must be greater than zero");

        uint deadline = block.timestamp + (durationDays * 1 days);
        campaigns[numCampaigns] = Campaign(msg.sender, goal, 0, deadline, false, 0);
        emit CampaignCreated(numCampaigns, msg.sender, goal, deadline);
        numCampaigns++;
    }

    function contribute(uint campaignId) public payable {
        Campaign storage campaign = campaigns[campaignId];

        require(!campaign.complete, "Campaign is already complete");
        require(block.timestamp <= campaign.deadline, "Campaign has already ended");
        require(msg.value > 0, "Contribution must be greater than zero");

        campaign.contributions[msg.sender] += msg.value;
        campaign.raised += msg.value;
        campaign.numContributions++;

        emit ContributionMade(campaignId, msg.sender, msg.value);
    }

    function checkCampaignCompletion(uint campaignId) public {
        Campaign storage campaign = campaigns[campaignId];

        if (block.timestamp > campaign.deadline && !campaign.complete) {
            if (campaign.raised >= campaign.goal) {
                campaign.creator.transfer(campaign.raised);
                campaign.complete = true;
                emit CampaignCompleted(campaignId, true);
            } else {
                campaign.complete = true;
                emit CampaignCompleted(campaignId, false);
            }
        }
    }
}
