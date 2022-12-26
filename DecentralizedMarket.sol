pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    // Mapping from item IDs to item structs
    mapping(uint256 => Item) public items;

    // Struct to represent an item for sale
    struct Item {
        // The name of the item
        string name;
        // The price of the item
        uint256 price;
        // The address of the seller
        address seller;
        // The address of the buyer (if the item has been sold)
        address buyer;
    }

    // Event to notify subscribers of a new item being listed for sale
    event NewItem(uint256 id, string name, uint256 price, address seller);

    // Function to allow a seller to list an item for sale
    function listItemForSale(uint256 _id, string memory _name, uint256 _price) public {
        // Ensure that the item is not already for sale
        require(items[_id].seller == address(0), "Item is already for sale");

        // Create a new item for sale
        items[_id] = Item(_name, _price, msg.sender, address(0));

        // Emit the new item event
        emit NewItem(_id, _name, _price, msg.sender);
    }

    // Function to allow a buyer to make an offer on an item
    function makeOffer(uint256 _id, uint256 _price) public {
        // Ensure that the item is for sale and that the offer price is equal to or greater than the asking price
        require(items[_id].seller != address(0), "Item is not for sale");
        require(_price >= items[_id].price, "Offer price is less than the asking price");

        // Set the buyer and transfer the funds to the seller
        items[_id].buyer = msg.sender;
        items[_id].seller.transfer(_price);
    }

    // Function to allow a seller to accept an offer on an item
    function acceptOffer(uint256 _id) public {
        // Ensure that the item is for sale and that an offer has been made
        require(items[_id].seller != address(0), "Item is not for sale");
        require(items[_id].buyer != address(0), "No offer has been made on the item");

        // Set the seller to the zero address and transfer ownership of the item to the buyer
        items[_id].seller = address(0);
        items[_id].buyer.transfer(items[_id].price);
    }
}
