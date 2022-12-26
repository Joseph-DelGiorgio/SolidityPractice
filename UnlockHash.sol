//script that uses a hash to unlock 1 Ethereum. Thinking of World Coin iris hash.

pragma solidity ^0.8.0;

contract Unlocker {
    bytes32 public unlockHash;
    bool public unlocked;

    constructor(bytes32 _unlockHash) public {
        unlockHash = _unlockHash;
        unlocked = false;
    }

    function unlock(bytes32 _hash) public {
        require(_hash == unlockHash, "Incorrect hash provided.");
        unlocked = true;
    }

    function unlockEthereum() public payable {
        require(unlocked, "Ethereum not yet unlocked.");
        msg.sender.transfer(1 ether);
    }
}
