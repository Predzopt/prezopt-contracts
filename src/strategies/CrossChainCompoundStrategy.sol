// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {PrezoptBridge} from "../bridge/PrezoptBridge.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract CrossChainCompoundStrategy is IStrategy {
    using SafeTransferLib for IERC20;

    IERC20 public asset;
    PrezoptBridge public bridge;
    uint32 public baseChainEid;
    address public baseCompoundStrategy;
    
    mapping(bytes32 => uint256) public pendingInvestments;
    mapping(bytes32 => uint256) public pendingWithdrawals;

    event CrossChainInvestment(bytes32 indexed requestId, uint256 amount);
    event CrossChainWithdrawal(bytes32 indexed requestId, uint256 amount);

    constructor(
        address _asset,
        address _bridge,
        uint32 _baseChainEid,
        address _baseCompoundStrategy
    ) {
        asset = IERC20(_asset);
        bridge = PrezoptBridge(_bridge);
        baseChainEid = _baseChainEid;
        baseCompoundStrategy = _baseCompoundStrategy;
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
            baseCompoundStrategy,
            baseChainEid,
            options
        );

        emit CrossChainInvestment(requestId, amount);
    }

    function withdraw(uint256 amount) external override {
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, amount, msg.sender));
        pendingWithdrawals[requestId] = amount;

        bytes memory payload = abi.encode("WITHDRAW", amount, msg.sender);
        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        
        emit CrossChainWithdrawal(requestId, amount);
    }

    function harvest() external override returns (uint256) {
        return 0;
    }

    function estimatedTotalAssets() external view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function getInvestmentQuote() external view returns (uint256) {
        return bridge.quote(baseChainEid, abi.encodePacked(uint16(1), uint128(200000))).nativeFee;
    }
}