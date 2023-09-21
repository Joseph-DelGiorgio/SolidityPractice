// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public token1;
    IERC20 public token2;
    address public owner;
    uint256 public token1ToToken2Ratio;  // Ratio of token1 to token2 (e.g., 1 ETH = 1000 DAI)
    uint256 public feePercentage;  // Fee percentage (0-100)

    event Swap(address indexed sender, uint256 token1Amount, uint256 token2Amount);

    constructor(address _token1Address, address _token2Address, uint256 _ratio, uint256 _feePercentage) {
        token1 = IERC20(_token1Address);
        token2 = IERC20(_token2Address);
        owner = msg.sender;
        token1ToToken2Ratio = _ratio;
        feePercentage = _feePercentage;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setSwapRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0, "Ratio must be greater than 0");
        token1ToToken2Ratio = _ratio;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Invalid fee percentage");
        feePercentage = _feePercentage;
    }

    function calculateToken2Amount(uint256 _token1Amount) internal view returns (uint256) {
        uint256 fee = (_token1Amount * feePercentage) / 100;
        return ((_token1Amount - fee) * token1ToToken2Ratio) / 1e18;
    }

    function swapTokens(uint256 _token1Amount) external {
        require(_token1Amount > 0, "Amount must be greater than 0");

        uint256 token2Amount = calculateToken2Amount(_token1Amount);

        require(token1.transferFrom(msg.sender, address(this), _token1Amount), "Token1 transfer failed");
        require(token2.transfer(msg.sender, token2Amount), "Token2 transfer failed");

        emit Swap(msg.sender, _token1Amount, token2Amount);
    }

    function withdrawTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner, _amount), "Token transfer failed");
    }

    function updateOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}
