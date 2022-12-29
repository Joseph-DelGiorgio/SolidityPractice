pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/utils/Address.sol";

contract Voting {
using SafeMath for uint256;
using Address for address;

// Mapping of voter addresses to their vote choice
mapping(address => uint8) public votes;

// Array of candidates
string[] public candidates;

// Total number of votes cast
uint256 public totalVotes;

// Constructor function to set up the candidates
constructor(string[] memory _candidates) public {
  candidates = _candidates;
}

// Function to cast a vote
function vote(uint8 _candidate) public {
  require(_candidate < candidates.length, "Invalid candidate");
  require(votes[msg.sender] == 0, "You have already voted");
  votes[msg.sender] = _candidate;
  totalVotes = totalVotes.add(1);
}

// Function to get the number of votes for a candidate
function getVotesForCandidate(uint8 _candidate) public view returns (uint256) {
  require(_candidate < candidates.length, "Invalid candidate");
  uint256 votesForCandidate = 0;
  for (uint256 i = 0; i < votes.length; i++) {
    if (votes[i] == _candidate) {
    votesForCandidate = votesForCandidate.add(1);
    }
  }
 return votesForCandidate;
}

// Function to get the name of a candidate
function getCandidateName(uint8 _candidate) public view returns (string memory) {
  require(_candidate < candidates.length, "Invalid candidate");
  return candidates[_candidate];
  }
 }
