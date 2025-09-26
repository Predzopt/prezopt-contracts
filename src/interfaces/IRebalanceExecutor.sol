// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRebalanceExecutor {
    struct RebalanceSignal {
        address fromStrategy;
        address toStrategy;
        uint256 amount;
        uint256 minOutput;
        uint256 expectedNetGain;
        uint256 timestamp;
        bytes signature;
    }

    function rebalance(RebalanceSignal calldata signal) external;
}