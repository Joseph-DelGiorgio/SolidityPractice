// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributor {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public dropAmount;

    mapping(address=>uint) private addressesClaimed;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(address indexed _from, uint _dropAmount);

    constructor(address token_, bytes32 merkleRoot_, uint256 dropAmount_) {
        token = token_;
        merkleRoot = merkleRoot_;
        dropAmount= dropAmount_;
    }

    function claim(bytes32[] calldata merkleProof) external {
        require(addressesClaimed[msg.sender]==0, 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        addressesClaimed[msg.sender]=1;
        require(IERC20(token).transfer(msg.sender, dropAmount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(msg.sender, dropAmount);
    }
}
