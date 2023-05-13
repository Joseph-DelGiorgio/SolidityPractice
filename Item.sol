// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Marketplace {
    struct Item {
        uint id;
        address payable seller;
        string name;
        string description;
        uint price;
        bool isSold;
    }

    mapping(uint => Item) public items;
    uint public nextItemId = 1;

    event ItemListed(
        uint id,
        address indexed seller,
        string name,
        string description,
        uint price
    );

    event ItemSold(
        uint indexed id,
        address indexed buyer,
        address seller
    );

    function listItem(string memory _name, string memory _description, uint _price) public {
        items[nextItemId] = Item(nextItemId, payable(msg.sender), _name, _description, _price, false);
        emit ItemListed(nextItemId, msg.sender, _name, _description, _price);
        nextItemId++;
    }

    function buyItem(uint _id) public payable {
        require(msg.value == items[_id].price, "Incorrect price");
        require(!items[_id].isSold, "Item already sold");

        items[_id].seller.transfer(msg.value);
        items[_id].isSold = true;

        emit ItemSold(_id, msg.sender, items[_id].seller);
    }
}
