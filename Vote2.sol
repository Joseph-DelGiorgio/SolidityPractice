// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Contract {
	enum Choices { Yes, No }
	
	struct Vote {
		Choices choice;
		address voter;
	}

	Vote none = Vote(Choices(0), address(0));

	Vote[] public votes; 

	function createVote(Choices choice) external {
		require(!hasVoted(msg.sender));
		votes.push(Vote(choice, msg.sender));
	}

	function changeVote(Choices choice) external {
		Vote storage vote = findVote(msg.sender);
		require(vote.voter != none.voter);
		vote.choice = choice;
	}

	function findVote(address voter) internal view returns(Vote storage) {
		for(uint i = 0; i < votes.length; i++) {
			if(votes[i].voter == voter) {
				return votes[i];
			}
		}
		return none;
	}

	function hasVoted(address voter) public view returns(bool) {
		return findVote(voter).voter == voter;
	}

	function findChoice(address voter) external view returns(Choices) {
		return findVote(voter).choice;
	}
}






//Tests.js

const { assert } = require('chai');
const CHOICES = {
    YES: 0,
    NO: 1,
}
describe('Contract', function () {
    let contract;
    let accounts;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();

        accounts = (await ethers.provider.listAccounts()).map((address) => ({
            address,
            signer: ethers.provider.getSigner(address)
        }));
    });

    it('should not allow an address to change a non-existent vote', async () => {
        let ex;
        try {
            await contract.changeVote(CHOICES.NO, { from: a1 });
        }
        catch (_ex) {
            ex = _ex;
        }
        assert(ex, "Expected the transaction to revert! This address cannot change a non-existing vote.");
    });

    describe('after voting yes', () => {
        before(async () => {
            await contract.connect(accounts[0].signer).createVote(CHOICES.YES);
        });

        it('should return true for this address having voted', async () => {
            assert(await contract.hasVoted(accounts[0].address));
        });

        it('should find a choice for the address', async () => {
            const choice = await contract.findChoice(accounts[0].address);
            assert.equal(choice, CHOICES.YES);
        });

        it('should not allow the same address to vote again', async () => {
            let ex;
            try {
                await contract.connect(accounts[0].signer).createVote(CHOICES.NO);
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, "Expected the transaction to revert! This address has already voted.");
        });

        describe('after changing to no', () => {
            before(async () => {
                await contract.connect(accounts[0].signer).changeVote(CHOICES.NO);
            });

            it('should update the vote', async () => {
                const choice = await contract.findChoice(accounts[0].address);
                assert.equal(choice, CHOICES.NO);
            });
        });
    });

    describe('after voting no', () => {
        before(async () => {
            await contract.connect(accounts[1].signer).createVote(CHOICES.NO);
        });

        it('should return true for this address having voted', async () => {
            assert(await contract.hasVoted(accounts[1].address));
        });

        it('should find a choice for the address', async () => {
            const choice = await contract.findChoice(accounts[1].address);
            assert.equal(choice, CHOICES.NO);
        });

        it('should not allow the same address to vote again', async () => {
            let ex;
            try {
                await contract.connect(accounts[1].signer).createVote(CHOICES.NO);
            }
            catch (_ex) {
                ex = _ex;
            }
            assert(ex, "Expected the transaction to revert! This address has already voted.");
        });

        describe('after changing to yes', () => {
            before(async () => {
                await contract.connect(accounts[1].signer).changeVote(CHOICES.YES);
            });

            it('should update the vote', async () => {
                const choice = await contract.findChoice(accounts[1].address);
                assert.equal(choice, CHOICES.YES);
            });
        });
    });
});
