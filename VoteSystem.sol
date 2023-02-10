pragma solidity ^0.8.0;

contract Voting {
  // Mapping of addresses to their vote count
  mapping (address => uint) public votes;

  // Mapping of candidate names to their vote count
  mapping (string => uint) public candidateVotes;

  // List of candidate names
  string[] public candidates;

  // Function to add a candidate
  function addCandidate(string memory candidate) public {
    candidates.push(candidate);
  }

  // Function to cast a vote
  function vote(string memory candidate) public {
    require(candidates.length > 0, "No candidates have been added yet.");
    require(votes[msg.sender] == 0, "You have already voted.");
    require(candidateVotes[candidate] >= 0, "Candidate does not exist.");

    // Increment the sender's vote count
    votes[msg.sender]++;

    // Increment the candidate's vote count
    candidateVotes[candidate]++;
  }

  // Function to retrieve the vote count of a candidate
  function getCandidateVoteCount(string memory candidate) public view returns (uint) {
    return candidateVotes[candidate];
  }

  // Function to retrieve the vote count of a voter
  function getVoterVoteCount(address voter) public view returns (uint) {
    return votes[voter];
  }
}
