//This was a guided practice via Smart Contract Programmer Youtube channel.
//Video link: https://youtu.be/n6nEPaE7KZ8

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

contract MerkleProof{
    function verify(
        bytes32[] memory proof, bytes32 root, bytes32 leaf, uint index
    ) public pure returns (bool){
        bytes32 hash= leaf;

        // recompute merkle root
        for (uint i=0; i< proof.length; i++){
            if (index % 2==0){
                hash= keccak256(abi.encodePacked(hash, proof[i]));
            }else{
                hash= keccak256(abi.encodePacked(proof[i], hash));
            }
            index = index/2;
        }
        return hash==root;
    }
}
