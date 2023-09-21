// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public token1;
    IERC20 public token2;
    address public owner;
    uint256 public token1ToToken2Ratio;  // Ratio of token1 to token2 (e.g., 1 ETH = 1000 DAI)
    uint256 public feePercentage;  // Fee percentage (0-100)
    uint256 public swapDuration;  // Duration in seconds for which swaps are allowed after start
    bool public swapsPaused;  // Flag to pause swaps

    uint256 public swapStartTime;  // Time when swaps are allowed

    event Swap(address indexed sender, uint256 token1Amount, uint256 token2Amount);
    event SwapsPaused();
    event SwapsResumed();

    constructor(address _token1Address, address _token2Address, uint256 _ratio, uint256 _feePercentage, uint256 _swapDuration) {
        token1 = IERC20(_token1Address);
        token2 = IERC20(_token2Address);
        owner = msg.sender;
        token1ToToken2Ratio = _ratio;
        feePercentage = _feePercentage;
        swapDuration = _swapDuration;
        swapsPaused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyDuringSwapWindow() {
        require(block.timestamp >= swapStartTime && block.timestamp < swapStartTime + swapDuration, "Swap window closed");
        _;
    }

    modifier swapsNotPaused() {
        require(!swapsPaused, "Swaps are paused");
        _;
    }

     modifier onlyAfterSwapWindow() {
        require(block.timestamp >= swapEndTime, "Swap window is still open");
        _;
    }

    function withdrawRemainingFunds() external onlyOwner onlyAfterSwapWindow {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No remaining funds");

        payable(msg.sender).transfer(contractBalance);
        emit RemainingFundsWithdrawn(contractBalance);
    }

    function updateSwapDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Duration must be greater than 0");
        swapDuration = _newDuration;
        swapEndTime = swapStartTime + _newDuration;
    }


    function setSwapRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0, "Ratio must be greater than 0");
        token1ToToken2Ratio = _ratio;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Invalid fee percentage");
        feePercentage = _feePercentage;
    }

    function setSwapDuration(uint256 _swapDuration) external onlyOwner {
        require(_swapDuration > 0, "Swap duration must be greater than 0");
        swapDuration = _swapDuration;
    }

    function startSwaps() external onlyOwner {
        swapStartTime = block.timestamp;
    }

    function pauseSwaps() external onlyOwner {
        swapsPaused = true;
        emit SwapsPaused();
    }

    function resumeSwaps() external onlyOwner {
        swapsPaused = false;
        emit SwapsResumed();
    }

    function calculateToken2Amount(uint256 _token1Amount) internal view returns (uint256) {
        uint256 fee = (_token1Amount * feePercentage) / 100;
        return ((_token1Amount - fee) * token1ToToken2Ratio) / 1e18;
    }

    function swapTokens(uint256 _token1Amount) external onlyDuringSwapWindow swapsNotPaused {
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

    function changeToken1Address(address _newToken1Address) external onlyOwner {
        require(_newToken1Address != address(0), "Invalid address");
        token1 = IERC20(_newToken1Address);
    }

    function changeToken2Address(address _newToken2Address) external onlyOwner {
        require(_newToken2Address != address(0), "Invalid address");
        token2 = IERC20(_newToken2Address);
    }
}
