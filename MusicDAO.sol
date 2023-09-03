// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MusicCollaborationDAO is Ownable {
    using Counters for Counters.Counter;

    struct MusicProject {
        string name;
        address[] contributors;
        mapping(address => uint256) contributions;
        uint256 totalContribution;
        uint256 royalties;
        bool isComplete;
        uint256 version;
    }

    mapping(uint256 => MusicProject) public musicProjects;
    Counters.Counter private projectCount;

    mapping(address => uint256) public memberShares;
    uint256 public totalShares;

    enum Vote { Approve, Reject }
    mapping(address => mapping(uint256 => Vote)) public votes;
    mapping(uint256 => uint256) public yesVotes;
    mapping(uint256 => uint256) public noVotes;
    uint256 public quorumPercentage = 50;

    event ProjectCreated(uint256 projectId, string projectName, address[] contributors, uint256 version);
    event ContributionAdded(uint256 projectId, address contributor, uint256 contribution);
    event ProjectCompleted(uint256 projectId, uint256 royalties);
    event VoteCasted(uint256 projectId, address voter, Vote vote);

    constructor() {
        memberShares[msg.sender] = 100;
        totalShares = 100;
    }

    modifier onlyContributor(uint256 _projectId) {
        require(isContributor(_projectId, msg.sender), "You are not a contributor to this project");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(msg.sender == musicProjects[_projectId].contributors[0], "Only the project owner can perform this action");
        _;
    }

    modifier onlyProjectNotComplete(uint256 _projectId) {
        require(!musicProjects[_projectId].isComplete, "This project is already completed");
        _;
    }

    function isContributor(uint256 _projectId, address _contributor) public view returns (bool) {
        return musicProjects[_projectId].contributions[_contributor] > 0;
    }

    function createProject(string memory _name, address[] memory _contributors) external {
        require(_contributors.length > 0, "At least one contributor is required");

        projectCount.increment();
        uint256 projectId = projectCount.current();
        musicProjects[projectId] = MusicProject({
            name: _name,
            contributors: _contributors,
            totalContribution: 0,
            royalties: 0,
            isComplete: false,
            version: 1
        });

        emit ProjectCreated(projectId, _name, _contributors, 1);
    }

    function addContribution(uint256 _projectId, uint256 _amount) external payable onlyContributor(_projectId) onlyProjectNotComplete(_projectId) {
        require(msg.value == _amount, "Please send the exact contribution amount in ETH");
        musicProjects[_projectId].contributions[msg.sender] += _amount;
        musicProjects[_projectId].totalContribution += _amount;

        emit ContributionAdded(_projectId, msg.sender, _amount);
    }

    function completeProject(uint256 _projectId) external onlyProjectOwner(_projectId) onlyProjectNotComplete(_projectId) {
        MusicProject storage project = musicProjects[_projectId];
        require(hasReachedQuorum(_projectId), "Not enough votes to complete the project");
        
        uint256 totalRoyalties = project.totalContribution;
        project.isComplete = true;
        project.royalties = totalRoyalties;

        for (uint256 i = 0; i < project.contributors.length; i++) {
            address contributor = project.contributors[i];
            uint256 contributorShare = (totalRoyalties * musicProjects[_projectId].contributions[contributor]) / project.totalContribution;
            memberShares[contributor] += contributorShare;
            totalShares += contributorShare;
        }

        project.version++;
        emit ProjectCompleted(_projectId, totalRoyalties);
    }

    function voteOnProject(uint256 _projectId, Vote _vote) external {
        require(isContributor(_projectId, msg.sender), "You are not a contributor to this project");
        require(votes[msg.sender][_projectId] == Vote.Approve, "You have already voted");
        if (_vote == Vote.Approve) {
            yesVotes[_projectId] += memberShares[msg.sender];
        } else {
            noVotes[_projectId] += memberShares[msg.sender];
        }
        votes[msg.sender][_projectId] = _vote;

        emit VoteCasted(_projectId, msg.sender, _vote);
    }

    function hasReachedQuorum(uint256 _projectId) public view returns (bool) {
        uint256 totalVotes = yesVotes[_projectId] + noVotes[_projectId];
        if (totalVotes == 0) {
            return false;
        }
        uint256 yesPercentage = (yesVotes[_projectId] * 100) / totalVotes;
        return yesPercentage >= quorumPercentage;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage > 0 && _percentage <= 100, "Percentage must be between 1 and 100");
        quorumPercentage = _percentage;
    }
}
