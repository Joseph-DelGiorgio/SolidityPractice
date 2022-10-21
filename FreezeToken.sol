// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FreezeFrameToken is ERC20, Pausable, Ownable{
    constructor() ERC20('FreezeFrameToken', 'FFT'){
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused override{
        super._beforeTokenTransfer(from, to, amount)
    }
}
