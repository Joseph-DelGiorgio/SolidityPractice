// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Prime {
	function dividesEvenly(uint x, uint y) public pure returns(bool) {
		return (x % y == 0);
	}

	function isPrime(uint x) public pure returns(bool) {
		for(uint i = 2; i <= x / 2; i++) {
			if(dividesEvenly(x, i)) {
				return false;
			}
		}
		return true;
	}
}


//Test.js

const { assert } = require('chai');

const mineBlock = () => ethers.provider.send("evm_mine");

describe('Prime', function () {
    let contract;
    before(async () => {
        const Prime = await ethers.getContractFactory("Prime");
        library = await Prime.deploy();
        await library.deployed();

        const PrimeGame = await ethers.getContractFactory("PrimeGame", { libraries: { Prime: library.address } });
        contract = await PrimeGame.deploy();
        await contract.deployed();
    });

    // blocks 0 & 1 are used for initialization
    describe('for block number 3', () => {
        before(async () => {
            await mineBlock();
        });

        it('should be a winner', async () => {
            const isWinner = await contract.callStatic.isWinner();
            assert(isWinner, "Expected block 3 to be a winner");
        });
    });

    describe('for block number 4', () => {
        before(async () => {
            await mineBlock();
        });

        it('should be a winner', async () => {
            const isWinner = await contract.callStatic.isWinner();
            assert(!isWinner, "Expected block 4 to not be a winner");
        });
    });

    describe('for block number 5', () => {
        before(async () => {
            await mineBlock();
        });

        it('should be a winner', async () => {
            const isWinner = await contract.callStatic.isWinner();
            assert(isWinner, "Expected block 5 to be a winner");
        });
    });

    describe('for block number 18', () => {
        before(async () => {
            for(let i = 5; i < 18; i++) {
                await mineBlock();
            }
        });

        it('should be a winner', async () => {
            const isWinner = await contract.callStatic.isWinner();
            assert(!isWinner, "Expected block 18 to not be a winner");
        });
    });

    describe('for block number 19', () => {
        before(async () => {
            await mineBlock();
        });

        it('should be a winner', async () => {
            const isWinner = await contract.callStatic.isWinner();
            assert(isWinner, "Expected block 19 to be a winner");
        });
    });
});
