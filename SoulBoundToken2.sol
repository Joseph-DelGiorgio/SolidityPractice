//This is an unflattened version of SoulBoundToken.sol (found in solidity practice repo)

//In order to make the Token truly Soulbound, you must install the "flattener" plugin, 
// you will be shown the imported code 
//Finally, comment out the "SafeTransferFrom" function.


pragma solidity ^0.8.2;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract SoulBound is ERC721URIStorage{

    address owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokendIds;

    constructor() ERC721("SoulBoundToken", "SBT"){
        owner=msg.sender;
    }

    mapping(address=>bool) public issuedTokens;

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    
    function issueToken(address to) onlyOwner external{
        issuedTokens[to]=true;
    }

    function claimToken(string memory tokenURI) public returns (uint256){
        require(issuedTokens[msg.sender], "Degree is not issued");

        _tokendIds.increment();
        uint256 newItemId= _tokendIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        personToToken[msg.sender]=tokenURI;
        issuedTokens[msg.sender]=false;
        return newItemId;
    }

    mapping(address=>string) public personToToken;

}
