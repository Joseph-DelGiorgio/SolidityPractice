pragma solidity ^0.8.0;

contract Lottery {
    // Mapping to store players' addresses and their deposited ether
    mapping (address => uint256) public players;

    // Event to notify the winner
    event WinnerAnnounced(address winner);

    // Function to allow players to join the lottery by sending ether
    function joinLottery() public payable {
        // Store the player's address and the amount they have sent
        players[msg.sender] = msg.value;
    }

    // Function to randomly select a winner and distribute the prize
    function pickWinner() public {
        // Get the total amount of ether deposited by all players
        uint256 totalEther = address(this).balance;

        // Check if there are any players in the game
        if (totalEther == 0) {
            return;
        }

        // Generate a random number between 0 and the total number of players
        uint256 numPlayers = players.length;
        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(now, numPlayers))) % numPlayers;

        // Find the address of the winner
        address winner;
        uint256 count = 0;
        for (address player : players) {
            if (count == winnerIndex) {
                winner = player;
                break;
            }
            count++;
        }

        // Transfer the prize to the winner
        winner.transfer(totalEther);

        // Emit an event to notify the winner
        emit WinnerAnnounced(winner);
    }
}
