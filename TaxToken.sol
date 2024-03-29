pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TaxToken is ERC20, Ownable, Pausable {
    uint public taxRate;
    uint public maxTxAmount;
    mapping(address => bool) public isTaxExempt;
    mapping(address => uint) public specificTaxRate;
    uint public minBalanceForNoTaxes;

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

       function setMaxTxAmount(uint _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function removeMaxTxAmount() external onlyOwner {
        maxTxAmount = type(uint).max;
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

    function setTaxExemptionForMultipleAddresses(address[] calldata accounts, bool status) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isTaxExempt[accounts[i]] = status;
        }
    }

    function setSpecificTaxRate(address account, uint rate) external onlyOwner {
        require(rate <= 100, "Tax rate should be between 0 and 100");
        specificTaxRate[account] = rate;
    }

    function removeSpecificTaxRate(address account) external onlyOwner {
        specificTaxRate[account] = 0;
    }

    function setMinBalanceForNoTaxes(uint _minBalance) external onlyOwner {
        minBalanceForNoTaxes = _minBalance;
    }

    function removeMinBalanceRequirement() external onlyOwner {
        minBalanceForNoTaxes = 0;
    }

    function transferAnyRemainingETHBalance(address payable recipient) external onlyOwner {
        require(address(this).balance > 0, "No ETH balance to transfer");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        bool isExempt = isTaxExempt[sender] || balanceOf(sender) >= minBalanceForNoTaxes;
        uint rate = specificTaxRate[sender] > 0 ? specificTaxRate[sender] : taxRate;
        uint taxAmount = isExempt ? 0 : amount * rate / 100;
        uint transferAmount = amount - taxAmount;
        super._transfer(sender, recipient, transferAmount);
        if(taxAmount > 0) {
            super._transfer(sender, address(0), taxAmount);
        }
    }
}