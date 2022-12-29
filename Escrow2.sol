// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Escrow {
	address public arbiter;
	address payable public beneficiary;
	address public depositor;

	bool public isApproved;

	constructor(address _arbiter, address payable _beneficiary) payable {
		arbiter = _arbiter;
		beneficiary = _beneficiary;
		depositor = msg.sender;
	}

	event Approved(uint);

	function approve() external {
		require(msg.sender == arbiter);
		uint balance = address(this).balance;
		(bool sent, ) = beneficiary.call{ value: balance }("");
		require(sent, "Failed to send Ether");
		emit Approved(balance);
		isApproved = true;
	}
}



//Approve.js

function approve(contract, arbiterSigner) {
    return contract.connect(arbiterSigner).approve();
}

module.exports = approve;







//Tests.js

const { assert } = require('chai');
const deposit = ethers.utils.parseEther("1");
const approve = require('../approve');
describe('Escrow', function () {
    let contract;
    let accounts = {};
    beforeEach(async () => {
        const roles = ['arbiter', 'beneficiary', 'depositor'];
        for (let i = 0; i < roles.length; i++) {
            const signer = ethers.provider.getSigner(i);
            const address = await signer.getAddress();
            accounts[roles[i]] = { signer, address }
        }

        const Contract = await ethers.getContractFactory("Escrow");
        contract = await Contract.connect(accounts.depositor.signer).deploy(
            accounts.arbiter.address,
            accounts.beneficiary.address,
            { value: deposit }
        );
    });

    it('should be funded', async () => {
        const balance = await ethers.provider.getBalance(contract.address);
        assert.equal(balance.toString(), deposit.toString());
    });

    describe("after approval", () => {
        let balanceBefore;
        before(async () => {
            balanceBefore = await ethers.provider.getBalance(accounts.beneficiary.address);
            await approve(contract, accounts.arbiter.signer);
        });

        it("should transfer balance to beneficiary", async () => {
            const after = await ethers.provider.getBalance(accounts.beneficiary.address);
            assert.equal(after.sub(balanceBefore).toString(), deposit.toString());
        });
    });
});
