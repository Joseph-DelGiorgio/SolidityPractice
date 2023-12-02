pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TaxToken is ERC20, Ownable, Pausable {
    uint public taxRate;

    event TaxRateChanged(uint oldRate, uint newRate);

    constructor(uint _taxRate) ERC20("TaxToken", "TT") {
        require(_taxRate <= 100, "Tax rate should be between 0 and 100");
        taxRate = _taxRate;
    }

    function setTaxRate(uint _taxRate) external onlyOwner {
        require(_taxRate <= 100, "Tax rate should be between 0 and 100");
        emit TaxRateChanged(taxRate, _taxRate);
        taxRate = _taxRate;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    function retrieveTokens(address to, address anotherToken) external onlyOwner {
        ERC20 alienToken = ERC20(anotherToken);
        alienToken.transfer(to, alienToken.balanceOf(address(this)));
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        uint taxAmount = amount * taxRate / 100;
        uint transferAmount = amount - taxAmount;
        super._transfer(sender, recipient, transferAmount);
        super._transfer(sender, address(0), taxAmount);
    }
}