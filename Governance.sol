// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Voting {
    enum VoteStates {Absent, Yes, No}
    uint constant VOTE_THRESHOLD = 10;

    struct Proposal {
        address target;
        bytes data;
        bool executed;
        uint yesCount;
        uint noCount;
        mapping (address => VoteStates) voteStates;
    }

    Proposal[] public proposals;

    event ProposalCreated(uint);
    event VoteCast(uint, address indexed);

    mapping(address => bool) members;

    constructor(address[] memory _members) {
        for(uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
        members[msg.sender] = true;
    }

    function newProposal(address _target, bytes calldata _data) external {
        require(members[msg.sender]);
        emit ProposalCreated(proposals.length);
        Proposal storage proposal = proposals.push();
        proposal.target = _target;
        proposal.data = _data;
    }

    function castVote(uint _proposalId, bool _supports) external {
        require(members[msg.sender]);
        Proposal storage proposal = proposals[_proposalId];

        // clear out previous vote
        if(proposal.voteStates[msg.sender] == VoteStates.Yes) {
            proposal.yesCount--;
        }
        if(proposal.voteStates[msg.sender] == VoteStates.No) {
            proposal.noCount--;
        }

        // add new vote
        if(_supports) {
            proposal.yesCount++;
        }
        else {
            proposal.noCount++;
        }

        // we're tracking whether or not someone has already voted
        // and we're keeping track as well of what they voted
        proposal.voteStates[msg.sender] = _supports ? VoteStates.Yes : VoteStates.No;

        emit VoteCast(_proposalId, msg.sender);

        if(proposal.yesCount == VOTE_THRESHOLD && !proposal.executed) {
            (bool success, ) = proposal.target.call(proposal.data);
            require(success);
        }
    }
}



//Test.js

const { assert } = require('chai');
describe('Voting', function () {
    const amount = 250;
    const interface = new ethers.utils.Interface(["function mint(uint) external"]);
    const data = interface.encodeFunctionData("mint", [amount]);
    let contract, signers;

    before(async () => {
        signers = await ethers.getSigners();

        const Voting = await ethers.getContractFactory("Voting");
        contract = await Voting.deploy(await Promise.all(signers.map(x => x.getAddress())));
        await contract.deployed();

        const Minter = await ethers.getContractFactory("Minter");
        minter = await Minter.deploy();
        await minter.deployed();

        await contract.connect(signers[0]).newProposal(minter.address, data);
    });

    describe('voting yes 9 times', () => {
        before(async () => {
            for(let i = 0; i < 9; i++) {
                const signer = signers[i];
                await contract.connect(signer).castVote(0, true);
            }
        });

        it('should not execute', async () => {
            assert.equal(await minter.minted(), 0);
        });

        describe('voting a 10th time', () => {
            before(async () => {
                const signer = signers[9];
                await contract.connect(signer).castVote(0, true);
            });

            it('should execute', async () => {
                assert.equal(await minter.minted(), amount);
            });
        });
    });
});
