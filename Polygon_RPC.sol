pragma solidity ^0.6.6;

contract RockPaperScissors {
    // Enum to represent the different moves that a player can make
    enum Move { Rock, Paper, Scissors }

    // Struct to represent a player in the game
    struct Player {
        address addr;
        Move move;
    }

    // Mapping from player addresses to player structs
    mapping(address => Player) public players;

    // The address of the contract owner
    address public owner;

    // Event to notify subscribers of the game result
    event GameResult(address winner, address loser);

    // Constructor to set the contract owner
    constructor() public {
        owner = msg.sender;
    }

    // Function to allow a player to make a move
    function makeMove(Move memory _move) public {
        // Ensure that the player has not already made a move
        require(players[msg.sender].move == Move.Rock, "Player has already made a move");

        // Set the player's move
        players[msg.sender].move = _move;
    }

    // Function to reveal the moves of both players and determine the winner
    function revealMoves() public {
        // Ensure that both players have made a move
        require(players[owner].move != Move.Rock, "Owner has not made a move");
        require(players[players[owner].addr].move != Move.Rock, "Other player has not made a move");

        // Determine the winner
        address winner;
        address loser;
        if (players[owner].move == players[players[owner].addr].move) {
            // It's a tie, so there is no winner or loser
            winner = address(0);
            loser = address(0);
        } else if (players[owner].move == Move.Rock && players[players[owner].addr].move == Move.Scissors ||
                   players[owner].move == Move.Paper && players[players[owner].addr].move == Move.Rock ||
                   players[owner].move == Move.Scissors && players[players[owner].addr].move == Move.Paper) {
            // The owner wins
            winner = owner;
            loser = players[owner].addr;
        } else {
            // The other player wins
            winner = players[owner].addr;
            loser = owner;
        }

        // Emit the game result event
        emit GameResult(winner, loser);
    }
}
