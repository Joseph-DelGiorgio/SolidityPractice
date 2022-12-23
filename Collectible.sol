// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Collectible {
	address owner;
	uint price;

	event Deployed(address indexed);
	constructor() {
		owner = msg.sender;
		emit Deployed(msg.sender);
	}

	event Transfer(address indexed, address indexed);
	function transfer(address recipient) external {
		require(msg.sender == owner);
		owner = recipient;
		emit Transfer(msg.sender, recipient);
	}

	event ForSale(uint, uint);
	function markPrice(uint _price) external {
		require(msg.sender == owner);
		price = _price;
		emit ForSale(price, block.timestamp);
	}

	event Purchase(uint, address indexed);
	function purchase() payable external {
		require(msg.value == price && price > 0);
		price = 0;
		(bool success, ) = owner.call{ value: msg.value }("");
		require(success);
		owner = msg.sender;
		emit Purchase(msg.value, msg.sender);
	} 
}

//Test.js

const { assert } = require('chai');

describe('Collectible', function () {
    let artifacts;
    before(async () => {
        artifacts = await hre.artifacts.readArtifact("Collectible");
    });
    
    it('should have indexed the Deployed event address', () => {
        const deployedEvent = artifacts.abi.find(x => x.name === "Deployed");
        assert(deployedEvent, "Expected to find a Deployed event on your contract ABI!");
        const {inputs} = deployedEvent;
        assert.equal(inputs.length, 1, "Expected to find a single input on the Deployed event!");
        assert(inputs[0].indexed, "Expected the address input to be indexed on the Deployed event!");
    });
    
    it('should have indexed the Transfer event addresses', () => {
        const transferEvent = artifacts.abi.find(x => x.name === "Transfer");
        assert(transferEvent, "Expected to find a Transfer event on your contract ABI!");
        const { inputs } = transferEvent;
        assert.equal(inputs.length, 2, "Expected to find a two inputs on the Transfer event!");
        assert(inputs[0].indexed, "Expected the first address input to be indexed on the Transfer event!");
        assert(inputs[1].indexed, "Expected the second address input to be indexed on the Transfer event!");
    });

    it('should have indexed the Purchase event addresses', () => {
        const purchaseEvent = artifacts.abi.find(x => x.name === "Purchase");
        assert(purchaseEvent, "Expected to find a Purchase event on your contract ABI!");
        const { inputs } = purchaseEvent;
        assert.equal(inputs.length, 2, "Expected to find a two inputs on the Purchase event!");
        assert(inputs[1].indexed, "Expected the address input to be indexed on the Purchase event!");
    });
});
