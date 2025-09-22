// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AaveStrategy} from "./AaveStrategy.sol";
import {PrezoptBridge} from "../bridge/PrezoptBridge.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract BaseAaveReceiver is AaveStrategy {
    using SafeTransferLib for IERC20;

    PrezoptBridge public bridge;
    uint32 public blockdagEid;
    address public blockdagStrategy;

    event AssetsReceived(uint256 amount, address indexed from);
    event YieldSent(uint256 amount, address indexed to);

    constructor(
        address _asset,
        address _pool,
        address _rewardsController,
        address _rewardToken,
        address _bridge,
        uint32 _blockdagEid,
        address _blockdagStrategy
    ) AaveStrategy(_asset, _pool, _rewardsController, _rewardToken) {
        bridge = PrezoptBridge(_bridge);
        blockdagEid = _blockdagEid;
        blockdagStrategy = _blockdagStrategy;
    }

    function receiveAndInvest(uint256 amount) external {
        require(msg.sender == address(bridge), "Only bridge");
        
        // Auto-invest received assets into Aave
        SafeTransferLib.safeApprove(address(asset), address(pool), 0);
        SafeTransferLib.safeApprove(address(asset), address(pool), amount);
        pool.supply(address(asset), amount, address(this), 0);
        
        emit AssetsReceived(amount, msg.sender);
    }

    function harvestAndBridge() external payable returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = address(asset);
        uint256 yield = pool.claimRewards(assets, type(uint256).max, address(this));
        
        if (yield > 0) {
            // Bridge yield back to BlockDAG
            SafeTransferLib.safeApprove(address(asset), address(bridge), yield);
            
            bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
            bridge.bridgeToken{value: msg.value}(
                address(asset),
                yield,
                blockdagStrategy,
                blockdagEid,
                options
            );
            
            emit YieldSent(yield, blockdagStrategy);
        }
        
        return yield;
    }

    function withdraw(uint256 amount) external override {
        pool.withdraw(address(asset), amount, msg.sender);
    }

    function emergencyWithdrawAndBridge(uint256 amount) external payable {
        require(msg.sender == address(bridge), "Only bridge");
        
        uint256 withdrawn = pool.withdraw(address(asset), amount, address(this));
        
        SafeTransferLib.safeApprove(address(asset), address(bridge), withdrawn);
        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        
        bridge.bridgeToken{value: msg.value}(
            address(asset),
            withdrawn,
            blockdagStrategy,
            blockdagEid,
            options
        );
    }
}