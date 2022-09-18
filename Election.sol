//This smart contract allows user to host an election with cadidates and voters.
//Keep in mind that in order to vote, addresses must be authorized by the contract owner prior.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Election{

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter{
        bool authorized;
        bool voted;
        uint vote;
    }

    address public owner;
    string public electionName;

    mapping(address=>Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;

    modifier onlyOwner(){
        require (msg.sender==owner);
        _;
    }
    
    function election(string memory _name) public{
        owner= msg.sender;
        electionName= _name;
    }

    function addCanidate(string memory _name) onlyOwner public{
        candidates.push(Candidate(_name, 0));
    }

    function getNumCandidate() public view returns(uint){
        return candidates.length;
    }

    function authorize(address _person) onlyOwner public{
        voters[_person].authorized =true;
    }

    function vote(uint _voteIndex) public{
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorized);

        voters[msg.sender].vote= _voteIndex;
        voters[msg.sender].voted = true;

        candidates[_voteIndex].voteCount += 1;
        totalVotes += 1;
    }

    function end() onlyOwner public{
        selfdestruct(payable(msg.sender));
    }
}
