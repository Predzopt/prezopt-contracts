// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract PZTStaking {
    using SafeTransferLib for ERC20;

    ERC20 public pzt;
    ERC20 public asset; // USDC
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public rewardsEarned;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(ERC20 _pzt, ERC20 _asset) {
        pzt = _pzt;
        asset = _asset;
    }

    function stake(uint256 amount) external {
        SafeTransferLib.safeTransferFrom(address(pzt), msg.sender, address(this), amount);
        uint256 newShares = totalShares == 0 ? amount : (amount * totalShares) / pzt.balanceOf(address(this));
        shares[msg.sender] += newShares;
        totalShares += newShares;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        uint256 shareValue = (amount * pzt.balanceOf(address(this))) / totalShares;
        shares[msg.sender] -= amount;
        totalShares -= amount;
        SafeTransferLib.safeTransfer(address(pzt), msg.sender, shareValue);
        emit Unstaked(msg.sender, amount);
    }

    function claim() external {
        uint256 reward = rewardsEarned[msg.sender];
        require(reward > 0, "No rewards");
        rewardsEarned[msg.sender] = 0;
        SafeTransferLib.safeTransfer(address(asset), msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function notifyReward(uint256 amount) external {
        SafeTransferLib.safeTransferFrom(address(asset), msg.sender, address(this), amount);
        // Distribute pro-rata
        if (totalShares > 0) {
            rewardsEarned[msg.sender] += amount; // simplified — should be per-share
        }
    }
}