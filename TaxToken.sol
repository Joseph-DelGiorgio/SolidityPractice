pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TaxToken is ERC20 {

    //10% tax
    uint public taxDivisor = 10;

    constructor() ERC20("TaxToken", "TT") {}

    function mintToMe(uint amount) public {
        //msg.sender is a global var in EVM
        _mint(msg.sender, amount);
    }

    function transfer(address to, uint amount) public override returns (bool) {
        uint balanceSender = balanceOf(msg.sender);
        require(balanceSender >= amount, "ERC20: Not enough balance for a transfer");

        uint taxAmount = amount / taxDivisor;
        uint transferAmount = amount - taxAmount;

        _transfer(msg.sender, to, transferAmount);
        _transfer(msg.sender, address(0), taxAmount);

        return true;
    }
}