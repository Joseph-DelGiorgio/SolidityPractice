pragma solidity ^0.8.0;

// Import the ERC-721 interface for NFTs
import "https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC721/ERC721.sol";

// The contract name is TicketSeller
contract TicketSeller {
  // The contract has a mapping from Ethereum addresses to tickets, where the ticket is represented as an NFT
  mapping (address => ERC721) public tickets;

  // The contract also has a variable that stores the ticket price in wei
  uint256 public ticketPrice;

  // The contract has variables that store the concert location, time, and date
  string public concertLocation;
  string public concertTime;
  uint256 public concertDate;

  // The contract has a constructor that sets the ticket price, location, time, and date
  constructor() public {
    ticketPrice = 500000000000000000; // 0.5 ether in wei
    concertLocation = "Madison Square Garden, New York City, NY";
    concertTime = "7:30";
    concertDate = 20221213; // December 13th, 2022
  }

  // The contract has a function that allows a user to purchase a ticket by sending the appropriate amount of ether to the contract
  function purchaseTicket() public payable {
    require(msg.value == ticketPrice, "Incorrect amount of ether sent");

    // Create a new ERC-721 token and assign it to the user
    ERC721 newTicket = new ERC721();
    tickets[msg.sender] = newTicket;

    // Transfer the token to the user
    newTicket.safeTransferFrom(address(this), msg.sender, newTicket.tokenId());
  }
}
