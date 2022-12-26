pragma solidity ^0.6.6;

contract DecentralizedPredictionMarket {
    // Mapping from market IDs to market structs
    mapping(uint256 => Market) public markets;

    // Struct to represent a prediction market
    struct Market {
        // The description of the event being predicted
        string description;
        // The outcome of the event (true or false)
        bool outcome;
        // The total supply of shares in the market
        uint256 totalSupply;
        // The price of each share
        uint256 price;
        // The address of the market creator
        address creator;
    }

    // Mapping from user addresses to their balances in each market
    mapping(address => mapping(uint256 => uint256)) public balances;

    // Event to notify subscribers of a new prediction market being created
    event NewMarket(uint256 id, string description, uint256 totalSupply, uint256 price, address creator);

    // Function to allow a user to create a prediction market
    function createMarket(uint256 _id, string memory _description, uint256 _totalSupply, uint256 _price) public {
        // Ensure that the market does not already exist
        require(markets[_id].creator == address(0), "Market already exists");

        // Create a new prediction market
        markets[_id] = Market(_description, false, _totalSupply, _price, msg.sender);

        // Emit the new market event
        emit NewMarket(_id, _description, _totalSupply, _price, msg.sender);
    }

    // Function to allow a user to buy shares in a prediction market
    function buyShares(uint256 _id, uint256 _quantity) public payable {
        // Ensure that the market exists and that there are enough shares available
        require(markets[_id].creator != address(0), "Market does not exist");
        require(_quantity * markets[_id].price <= msg.value, "Insufficient funds");
        require(_quantity <= markets[_id].totalSupply, "Not enough shares available");

        // Decrement the total supply of shares and transfer the funds to the market creator
        markets[_id].totalSupply -= _quantity;
        markets[_id].creator.transfer(msg.value);

        // Increment the buyer's balance of shares
        balances[msg.sender][_id] += _quantity;
    }

    // Function to allow a user to sell shares in a prediction market
    function sellShares(uint256 _id, uint256 _quantity) public {
        // Ensure that the market exists and that the user owns enough shares
        require(markets[_id].creator != address(0), "Market does not exist");
        require(_quantity <= balances[msg.sender][_id], "Not enough shares owned");

        // Increment the total supply of shares and transfer the funds to the seller
        markets[_id].totalSupply += _quantity;
        msg.sender.transfer(markets[_id].price * _quantity);

        // Decrement the seller's balance of shares
        balances[msg.sender][_id] -= _quantity;
    }

    // Function to allow the market creator to resolve the prediction market and set the outcome
    
        function resolveMarket(uint256 _id, bool _outcome) public {
        // Ensure that the market exists and that the caller is the market creator
        require(markets[_id].creator != address(0), "Market does not exist");
        require(msg.sender == markets[_id].creator, "Only the market creator can resolve the market");

        // Set the outcome of the market
        markets[_id].outcome = _outcome;
    }

    // Function to allow a user to claim their winnings (if they correctly predicted the outcome)
    function claimWinnings(uint256 _id) public {
        // Ensure that the market exists and has been resolved
        require(markets[_id].creator != address(0), "Market does not exist");
        require(markets[_id].outcome != false, "Market has not been resolved");

        // Calculate the user's winnings (the number of shares they own multiplied by the price of each share)
        uint256 winnings = balances[msg.sender][_id] * markets[_id].price;

        // Transfer the winnings to the user
        msg.sender.transfer(winnings);

        // Reset the user's balance of shares in the market
        balances[msg.sender][_id] = 0;
    }
}

