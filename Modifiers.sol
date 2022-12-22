// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contract {
	address owner;
	uint configA;
	uint configB;
	uint configC;

	constructor() {
		owner = msg.sender;
	}

	function setA(uint _configA) public onlyOwner {
		configA = _configA;
	}

	function setB(uint _configB) public onlyOwner {
		configB = _configB;
	}

	function setC(uint _configC) public onlyOwner {
		configC = _configC;
	}

	modifier onlyOwner {
		require(owner==msg.sender);
		_;
	}
}

//Tests.js

const { assert } = require('chai');

describe('Contract', function () {
    let contract;
    before(async () => {
        const Contract = await ethers.getContractFactory("Contract");
        contract = await Contract.deploy();
        await contract.deployed();
    });

    it('should fail when another account attempts to set a config variable', async () => {
        const vals = ['A', 'B', 'C'];
        const other = ethers.provider.getSigner(1);
        for (let i = 0; i < vals.length; i++) {
            const val = vals[i];
            const methodName = `set${val}`;
            let ex;
            try {
                await contract.connect(other)[methodName](1);
            }
            catch (_ex) { ex = _ex; }
            if (!ex) {
                assert.fail(`Call to ${methodName} with non-owner did not fail!`);
            }
        }
    });

    it('should not fail when owner attempts to set a config variable', async () => {
        const vals = ['A', 'B', 'C'];
        for (let i = 0; i < vals.length; i++) {
            const val = vals[i];
            const methodName = `set${val}`;
            await contract[methodName](1);
        }
    });
});
