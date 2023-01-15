//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Casino {

  struct ProposedBet {
    address sideA;
    uint value;
    uint placedAt;
    bool accepted;   
  }    // struct ProposedBet


  struct AcceptedBet {
    address sideB;
    uint acceptedAt;
    uint randomB;
  }   // struct AcceptedBet

  // Proposed bets, keyed by the commitment value
  mapping(uint => ProposedBet) public proposedBet;

  // Accepted bets, also keyed by commitment value
  mapping(uint => AcceptedBet) public acceptedBet;

  event BetProposed (
    uint indexed _commitment,
    uint value
  );

  event BetAccepted (
    uint indexed _commitment,
    address indexed _sideA
  );


  event BetSettled (
    uint indexed _commitment,
    address winner,
    address loser,
    uint value    
  );


  // Called by sideA to start the process
  function proposeBet(uint _commitment) external payable {
    require(proposedBet[_commitment].value == 0,
      "there is already a bet on that commitment");
    require(msg.value > 0,
      "you need to actually bet something");

    proposedBet[_commitment].sideA = msg.sender;
    proposedBet[_commitment].value = msg.value;
    proposedBet[_commitment].placedAt = block.timestamp;
    // accepted is false by default

    emit BetProposed(_commitment, msg.value);
  }  // function proposeBet


  // Called by sideB to continue
  function acceptBet(uint _commitment, uint _random) external payable {

    require(!proposedBet[_commitment].accepted,
      "Bet has already been accepted");
    require(proposedBet[_commitment].sideA != address(0),
      "Nobody made that bet");
    require(msg.value == proposedBet[_commitment].value,
      "Need to bet the same amount as sideA");

    acceptedBet[_commitment].sideB = msg.sender;
    acceptedBet[_commitment].acceptedAt = block.timestamp;
    acceptedBet[_commitment].randomB = _random;
    proposedBet[_commitment].accepted = true;

    emit BetAccepted(_commitment, proposedBet[_commitment].sideA);
  }   // function acceptBet


  // Called by sideA to reveal their random value and conclude the bet
  function reveal(uint _random) external {
    uint _commitment = uint256(keccak256(abi.encodePacked(_random)));
    address payable _sideA = payable(msg.sender);
    address payable _sideB = payable(acceptedBet[_commitment].sideB);
    uint _agreedRandom = _random ^ acceptedBet[_commitment].randomB;
    uint _value = proposedBet[_commitment].value;

    require(proposedBet[_commitment].sideA == msg.sender,
      "Not a bet you placed or wrong value");
    require(proposedBet[_commitment].accepted,
      "Bet has not been accepted yet");

    // Pay and emit an event
    if (_agreedRandom % 2 == 0) {
      // sideA wins
      _sideA.transfer(2*_value);
      emit BetSettled(_commitment, _sideA, _sideB, _value);
    } else {
      // sideB wins
      _sideB.transfer(2*_value);
      emit BetSettled(_commitment, _sideB, _sideA, _value);      
    }

    // Cleanup
    delete proposedBet[_commitment];
    delete acceptedBet[_commitment];

  }  // function reveal

}   // contract Casino









//Casino-Test.js


const chai = require("chai")
const expect = chai.expect
chai.use(require('chai-as-promised'))

const valA = ethers.utils.keccak256(0xBAD060A7)
const hashA = ethers.utils.keccak256(valA)
const valBwin = ethers.utils.keccak256(0x600D60A7)
const valBlose = ethers.utils.keccak256(0xBAD060A7)

// Chai's expect(<operation>).to.be.revertedWith behaves
// strangely, so I'm implementing that functionality myself
// with try/catch
const interpretErr = err => {
  if (err.reason)
    return err.reason
  else
    return err.stackTrace[0].message.value.toString('ascii')
}

describe("Casino", async () => {
  it("Not allow you to propose a zero wei bet", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    try {
      tx = await c.proposeBet(hashA)
      rcpt = await tx.wait()

      // If we get here, it's a fail
      expect("this").to.equal("fail")
    } catch(err) {
      expect(interpretErr(err)).to
        .match(/you need to actually bet something/)
    }
  })   // it "Not allow you to bet zero wei"

  it("Not allow you to accept a bet that doesn't exist", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    try {
      tx = await c.acceptBet(hashA, valBwin, {value: 10})
      rcpt = await tx.wait()
      expect("this").to.equal("fail")
    } catch (err) {
        expect(interpretErr(err)).to
          .match(/Nobody made that bet/)
    }
  })   // it "Not allow you to accept a bet that doesn't exist" 

  it("Allow you to propose and accept bets", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    tx = await c.proposeBet(hashA, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")
    tx = await c.acceptBet(hashA, valBwin, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetAccepted")      
  })   // it "Allow you to accept a bet"

  it("Not allow you to accept an already accepted bet", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    tx = await c.proposeBet(hashA, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")
    tx = await c.acceptBet(hashA, valBwin, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetAccepted")
    try {
      tx = await c.acceptBet(hashA, valBwin, {value: 10})
      rcpt = await tx.wait()   
      expect("this").to.equal("fail")      
    } catch (err) {
        expect(interpretErr(err)).to
          .match(/Bet has already been accepted/)
    }          
  })   // it "Not allow you to accept an already accepted bet" 


  it("Not allow you to accept with the wrong amount", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    tx = await c.proposeBet(hashA, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")
    try {
      tx = await c.acceptBet(hashA, valBwin, {value: 11})
      rcpt = await tx.wait()   
      expect("this").to.equal("fail")      
    } catch (err) {
        expect(interpretErr(err)).to
          .match(/Need to bet the same amount as sideA/)
    }          
  })   // it "Not allow you to accept with the wrong amount"   


  it("Not allow you to reveal with wrong value", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    tx = await c.proposeBet(hashA, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")
    tx = await c.acceptBet(hashA, valBwin, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetAccepted")
    try {
      tx = await c.reveal(valBwin)
      rcpt = await tx.wait()   
      expect("this").to.equal("fail")      
    } catch (err) {
        expect(interpretErr(err)).to
          .match(/Not a bet you placed or wrong value/)
    }          
  })   // it "Not allow you to accept an already accepted bet" 


  it("Not allow you to reveal before bet is accepted", async () => {
    f = await ethers.getContractFactory("Casino")
    c = await f.deploy()

    tx = await c.proposeBet(hashA, {value: 10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")
    try {
      tx = await c.reveal(valA)
      rcpt = await tx.wait()   
      expect("this").to.equal("fail")      
    } catch (err) {
        expect(interpretErr(err)).to
          .match(/Bet has not been accepted yet/)
    }          
  })   // it "Not allow you to reveal before bet is accepted"  

  it("Work all the way through (B wins)", async () => {
    signer = await ethers.getSigners()
    f = await ethers.getContractFactory("Casino")
    cA = await f.deploy()
    cB = cA.connect(signer[1])

    tx = await cA.proposeBet(hashA, {value: 1e10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")

    tx = await cB.acceptBet(hashA, valBwin, {value: 1e10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetAccepted")      

    // A sends the transaction, so the change due to the
    // bet will only be clearly visible in B

    preBalanceB = await ethers.provider.getBalance(signer[1].address)    
    tx = await cA.reveal(valA)
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetSettled")
    postBalanceB = await ethers.provider.getBalance(signer[1].address)        
    deltaB = postBalanceB.sub(preBalanceB)
    expect(deltaB.toNumber()).to.equal(2e10)   


  })   // it "Work all the way through (B wins)"


  it("Work all the way through (A wins)", async () => {
    signer = await ethers.getSigners()
    f = await ethers.getContractFactory("Casino")
    cA = await f.deploy()
    cB = cA.connect(signer[1])

    tx = await cA.proposeBet(hashA, {value: 1e10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetProposed")

    tx = await cB.acceptBet(hashA, valBlose, {value: 1e10})
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetAccepted")      

    // A sends the transaction, so the change due to the
    // bet will only be clearly visible in B
    preBalanceB = await ethers.provider.getBalance(signer[1].address)    
    tx = await cA.reveal(valA)
    rcpt = await tx.wait()
    expect(rcpt.events[0].event).to.equal("BetSettled")
    postBalanceB = await ethers.provider.getBalance(signer[1].address)        
    deltaB = postBalanceB.sub(preBalanceB)
    expect(deltaB.toNumber()).to.equal(0) 
  })   // it "Work all the way through (A wins)"


})     // describe("Casino")
