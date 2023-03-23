// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Project {
        uint id;
        address payable creator;
        uint fundingGoal;
        uint deadline;
        uint totalFundsRaised;
        bool active;
        uint numMilestones;
        uint currentMilestone;
    }

    struct Milestone {
        uint id;
        uint amount;
        string description;
        bool completed;
    }

    uint private nextProjectId;
    mapping(uint => Project) private projects;
    mapping(uint => mapping(uint => Milestone)) private milestones;
    mapping(uint => mapping(address => uint)) private contributions;

    event ProjectCreated(uint indexed projectId, address indexed creator, uint fundingGoal, uint deadline);
    event ContributionReceived(uint indexed projectId, address indexed contributor, uint amount);
    event MilestoneCompleted(uint indexed projectId, uint indexed milestoneId);
    event FundsReleased(uint indexed projectId, uint amount);

    modifier onlyProjectCreator(uint projectId) {
        require(msg.sender == projects[projectId].creator, "Only project creator can call this function.");
        _;
    }

    modifier projectExists(uint projectId) {
        require(projects[projectId].id == projectId && projects[projectId].active, "Project does not exist or is not active.");
        _;
    }

    modifier milestoneExists(uint projectId, uint milestoneId) {
        require(milestones[projectId][milestoneId].id == milestoneId, "Milestone does not exist.");
        _;
    }

    modifier milestoneNotCompleted(uint projectId, uint milestoneId) {
        require(!milestones[projectId][milestoneId].completed, "Milestone is already completed.");
        _;
    }

    function createProject(uint fundingGoal, uint deadline, uint numMilestones) public {
        require(fundingGoal > 0, "Funding goal must be greater than zero.");
        require(deadline > block.timestamp, "Deadline must be in the future.");
        require(numMilestones > 0, "Number of milestones must be greater than zero.");

        uint projectId = nextProjectId++;
        projects[projectId] = Project(projectId, payable(msg.sender), fundingGoal, deadline, 0, true, numMilestones, 0);

        emit ProjectCreated(projectId, msg.sender, fundingGoal, deadline);
    }

    function createMilestone(uint projectId, uint milestoneId, uint amount, string memory description) public onlyProjectCreator(projectId) {
        require(milestoneId < projects[projectId].numMilestones, "Invalid milestone id.");
        require(amount > 0, "Milestone amount must be greater than zero.");

        milestones[projectId][milestoneId] = Milestone(milestoneId, amount, description, false);
    }

    function contribute(uint projectId) public payable projectExists(projectId) {
        require(projects[projectId].deadline > block.timestamp, "Project deadline has passed.");
        require(msg.value > 0, "Contribution must be greater than zero.");

        projects[projectId].totalFundsRaised += msg.value;
        contributions[projectId][msg.sender] += msg.value;

        emit ContributionReceived(projectId, msg.sender, msg.value);
    }

    function completeMilestone(uint projectId, uint milestoneId) public onlyProjectCreator(projectId) projectExists(projectId) milestoneExists(projectId, milestoneId) milestoneNotCompleted(uint projectId, uint milestoneId) {
        require(projects[projectId].totalFundsRaised >= milestones[projectId][milestoneId].amount, "Insufficient funds raised to complete milestone.");
            milestones[projectId][milestoneId].completed = true;
    projects[projectId].currentMilestone = milestoneId + 1;

    emit MilestoneCompleted(projectId, milestoneId);

    // Release funds for the completed milestone
    uint amountToRelease = milestones[projectId][milestoneId].amount;
    projects[projectId].creator.transfer(amountToRelease);

    emit FundsReleased(projectId, amountToRelease);

    // Check if the last milestone is completed, deactivate the project
    if (projects[projectId].currentMilestone == projects[projectId].numMilestones) {
        projects[projectId].active = false;
    }
}

function getProject(uint projectId) public view returns (Project memory) {
    return projects[projectId];
}

function getMilestone(uint projectId, uint milestoneId) public view returns (Milestone memory) {
    return milestones[projectId][milestoneId];
}

function getContribution(uint projectId, address contributor) public view returns (uint) {
    return contributions[projectId][contributor];
}

