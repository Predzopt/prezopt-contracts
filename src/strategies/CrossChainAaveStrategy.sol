// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {PrezoptBridge} from "../bridge/PrezoptBridge.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract CrossChainAaveStrategy is IStrategy {
    using SafeTransferLib for IERC20;

    IERC20 public asset;
    PrezoptBridge public bridge;
    uint32 public baseChainEid;
    address public baseAaveStrategy;
    
    mapping(bytes32 => uint256) public pendingInvestments;
    mapping(bytes32 => uint256) public pendingWithdrawals;

    event CrossChainInvestment(bytes32 indexed requestId, uint256 amount);
    event CrossChainWithdrawal(bytes32 indexed requestId, uint256 amount);

    constructor(
        address _asset,
        address _bridge,
        uint32 _baseChainEid,
        address _baseAaveStrategy
    ) {
        asset = IERC20(_asset);
        bridge = PrezoptBridge(_bridge);
        baseChainEid = _baseChainEid;
        baseAaveStrategy = _baseAaveStrategy;
    }

    function invest(uint256 amount) external payable override {
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, amount, msg.sender));
        pendingInvestments[requestId] = amount;

        SafeTransferLib.safeTransferFrom(address(asset), msg.sender, address(this), amount);
        SafeTransferLib.safeApprove(address(asset), address(bridge), amount);

        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        
        bridge.bridgeToken{value: msg.value}(
            address(asset),
            amount,
            baseAaveStrategy,
            baseChainEid,
            options
        );

        emit CrossChainInvestment(requestId, amount);
    }

    function withdraw(uint256 amount) external override {
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, amount, msg.sender));
        pendingWithdrawals[requestId] = amount;

        // Send withdrawal request to Base chain
        bytes memory payload = abi.encode("WITHDRAW", amount, msg.sender);
        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        
        // This would trigger withdrawal on Base chain Aave strategy
        emit CrossChainWithdrawal(requestId, amount);
    }

    function harvest() external override returns (uint256) {
        // Cross-chain harvest would require more complex coordination
        // For now, return 0 as harvest happens on Base chain
        return 0;
    }

    function estimatedTotalAssets() external view override returns (uint256) {
        // This would need to query Base chain for actual assets
        // For now, return local balance
        return asset.balanceOf(address(this));
    }

    function getInvestmentQuote() external view returns (uint256) {
        return bridge.quote(baseChainEid, abi.encodePacked(uint16(1), uint128(200000))).nativeFee;
    }
}