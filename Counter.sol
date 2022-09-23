// This was a guided practice via Dapp University. Video Link: https://youtu.be/eoQJ6nFZOcs

//I have attached the solidity smart contract and the javascript testing contract below.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter{
    string public name;
    uint public count;

    constructor(){
        name= "My Counter";
        count=1;
    }

    function increment() public returns(uint newCount){
        count++;
        return count;
    }

    function decrement() public returns(uint newCount){
        count--;
        return count;
    }

    function getCount() public view returns(uint){
        return count;
    }

    function getName() public view returns(string memory currentName){
        return name;
    }

    function setName(string memory _newName) public returns(string memory newName){
        name= _newName;
        return name;
    }
}


// Here is the testing contract for Hardhat (written in Javascript)

const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Counter', () => {
  let counter

  beforeEach(async () => {
    // Load contract
    const Counter = await ethers.getContractFactory('Counter')

    // Deploy contract
    counter = await Counter.deploy('My Counter', 1)
  })

  describe('Deployment', () => {

    it('sets the name', async () => {
      expect(await counter.name()).to.equal('My Counter')
    })

    it('sets the initial count', async () => {
      expect(await counter.count()).to.equal(1)
    })

  })

  describe('Counting', () => {
    let transaction, result

    it('reads the count from the "count" public variable', async () => {
      expect(await counter.count()).to.equal(1)
    })

    it('reads the count from the "getCount()" function', async () => {
      expect(await counter.getCount()).to.equal(1)
    })

    it('increments the count', async () => {
      transaction = await counter.increment()
      await transaction.wait()

      let count = await counter.count()
      expect(count).to.equal(2)

      transaction = await counter.increment()
      await transaction.wait()
      count = await counter.count()

      count = await counter.count()
      expect(count).to.equal(3)
    })

    it('decrements the count', async () => {

      let count = await counter.count()

      transaction = await counter.decrement()
      await transaction.wait()

      count = await counter.count()

      // Cannot decrement account below 0
      await expect(counter.decrement()).to.be.reverted

    })

    it('reads the name from the "name" public variable', async () => {
      expect(await counter.name()).to.equal('My Counter')
    })

    it('reads the name from the "#getName()" function', async () => {
      expect(await counter.getName()).to.equal('My Counter')
    })

    it('updates the name', async () => {
      transaction = await counter.setName('New Name')
      await transaction.wait()
      expect(await counter.name()).to.equal('New Name')
    })

  })

})
