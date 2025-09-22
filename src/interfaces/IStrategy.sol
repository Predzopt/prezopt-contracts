// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStrategy {
    function invest(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
    function harvest() external returns (uint256);
    function estimatedTotalAssets() external view returns (uint256);
}