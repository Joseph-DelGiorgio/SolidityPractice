// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TravisCoin is ERC20 {
    constructor(
        address[] memory recipients
    ) ERC20("TravisCoin", "TRVS") {
        require(recipients.length == 5, "There must be exactly 5 recipients");

        uint256 initialSupply = 5000 * (10 ** uint256(decimals()));
        _mint(address(this), initialSupply);

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(address(this), recipients[i], initialSupply / 5);
        }
    }
}