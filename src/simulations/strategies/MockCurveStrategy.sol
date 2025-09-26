// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../../interfaces/IStrategy.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract MockCurveStrategy is IStrategy {
    IERC20 public asset;
    IERC20 public rewardToken;
    
    uint256 public baseAPY = 300; // 3% APY
    uint256 public rewardAPY = 400; // 4% reward APY
    uint256 public slippageBps = 10; // 0.1% slippage
    uint256 public totalDeposited;
    uint256 public lastUpdateTime;
    uint256 public accruedYield;

    event YieldAccrued(uint256 amount);
    event RewardsHarvested(uint256 amount);
    event SlippageApplied(uint256 amount);

    constructor(address _asset, address _rewardToken) {
        asset = IERC20(_asset);
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
    }

    function invest(uint256 amount) external override {
        _updateYield();
        
        SafeTransferLib.safeTransferFrom(address(asset), msg.sender, address(this), amount);
        
        // Apply slippage on entry
        uint256 slippage = (amount * slippageBps) / 10000;
        uint256 effectiveAmount = amount - slippage;
        totalDeposited += effectiveAmount;
        
        emit SlippageApplied(slippage);
    }

    function withdraw(uint256 amount) external override {
        _updateYield();
        
        require(totalDeposited >= amount, "Insufficient balance");
        
        // Apply slippage on exit
        uint256 slippage = (amount * slippageBps) / 10000;
        uint256 effectiveAmount = amount - slippage;
        
        totalDeposited -= amount;
        
        SafeTransferLib.safeTransfer(address(asset), msg.sender, effectiveAmount);
        emit SlippageApplied(slippage);
    }

    function harvest() external override returns (uint256) {
        _updateYield();
        
        uint256 rewardAmount = (totalDeposited * rewardAPY * (block.timestamp - lastUpdateTime)) / (365 days * 10000);
        
        if (rewardAmount > 0) {
            (bool success,) = address(rewardToken).call(
                abi.encodeWithSignature("mint(address,uint256)", address(this), rewardAmount)
            );
            if (success) {
                emit RewardsHarvested(rewardAmount);
                return rewardAmount;
            }
        }
        
        return 0;
    }

    function estimatedTotalAssets() external view override returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        uint256 projectedYield = (totalDeposited * baseAPY * timeElapsed) / (365 days * 10000);
        return totalDeposited + accruedYield + projectedYield;
    }

    function _updateYield() internal {
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (timeElapsed > 0 && totalDeposited > 0) {
            uint256 newYield = (totalDeposited * baseAPY * timeElapsed) / (365 days * 10000);
            accruedYield += newYield;
            lastUpdateTime = block.timestamp;
            
            emit YieldAccrued(newYield);
        }
    }

    function getCurrentAPY() external view returns (uint256) {
        return baseAPY + rewardAPY;
    }

    function setAPY(uint256 _baseAPY, uint256 _rewardAPY) external {
        baseAPY = _baseAPY;
        rewardAPY = _rewardAPY;
    }

    function setSlippage(uint256 _slippageBps) external {
        slippageBps = _slippageBps;
    }
}