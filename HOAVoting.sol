// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HOAVoting {
    address public admin;
    uint256 public proposalCount;
    
    struct Proposal {
        string description;
        uint256 voteCount;
        mapping(address => bool) votes;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public memberLastVoted;
    
    event ProposalCreated(uint256 proposalId, string description);
    event VoteCasted(uint256 proposalId, address voter);
    
    constructor() {
        admin = msg.sender;
        proposalCount = 0;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    function createProposal(string memory _description) public onlyAdmin {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            voteCount: 0
        });
        emit ProposalCreated(proposalCount, _description);
    }
    
    modifier onlyAfterVotingInterval(address _voter) {
        require(block.timestamp >= memberLastVoted[_voter] + 1 weeks, "You can only vote once per week");
        _;
    }
    
    function vote(uint256 _proposalId) public onlyAfterVotingInterval(msg.sender) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].votes[msg.sender], "Already voted for this proposal");
        
        proposals[_proposalId].votes[msg.sender] = true;
        proposals[_proposalId].voteCount++;
        
        memberLastVoted[msg.sender] = block.timestamp;
        
        emit VoteCasted(_proposalId, msg.sender);
    }
    
    function getProposalDetails(uint256 _proposalId) public view returns (string memory, uint256) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.description, proposal.voteCount);
    }
}
