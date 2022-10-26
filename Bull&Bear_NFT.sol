//This contract deploys a dynamic NFT that turns into a bull or a bear,
//depending on the price action of ETH/USD via Chainlink price feed.

//This was a guided practice via Alchemy YouTube channel. Video link: https://youtu.be/hNdXSMKLDi4

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports. This only works on a local dev network
// and will not work on any test or main livenets.
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint public /*immutable*/ interval;
    uint public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

    // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];

    event TokensUpdated(string marketTrend);

    constructor(uint updateInterval) ERC721("Bull&Bear", "BBTK") {
        //sets the keeper update interval.
        interval=updateInterval;
        lastTimeStamp= block.timestamp;

        priceFeed= AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

        currentPrice= getLatestPrice();
    }

    function safeMint(address to) public {
        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log(
            "DONE!!! minted token ",
            tokenId,
            " and assigned token url: ",
            defaultUri
        );
    }

    function checkUpkeep(bytes calldata /*checkdata*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/){
        upkeepNeeded= (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /*performData*/) external override{
        if ((block.timestamp - lastTimeStamp) > interval){
            lastTimeStamp= block.timestamp;
            int latestPrice= getLatestPrice();

            if(latestPrice==currentPrice){
                return;
            }

            if(latestPrice < currentPrice){
                //bear
                updateAllTokenUris("bear");
            } else{
                //bull
                updateAllTokenUris("bull");
            }

            currentPrice= latestPrice;
        }
    }

    function getLatestPrice() public view returns(int256){
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /* uint timeStamp*/,
            /*uint80 answeredInRound*/
        )= priceFeed.latestRoundData();

        return price;
    }

    function updateAllTokenUris(string memory trend) internal{
        if(compareStrings("bear", trend)){
            for(uint i=0; i< _tokenIdCounter.current(); i++){
                _setTokenURI(i, bearUrisIpfs[0]);
            }
        }else{
            for(uint i=0; i< _tokenIdCounter.current(); i++){
                _setTokenURI(i, bullUrisIpfs[0]);
            }
        }

        emit TokensUpdated(trend);
    }

    function setInterval(uint256 newInterval) public onlyOwner{
        interval= newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner{
        priceFeed= AggregatorV3Interface(newFeed);
    }

    function compareStrings(string memory a, string memory b) internal pure returns(bool){
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
    
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
