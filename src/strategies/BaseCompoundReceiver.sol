// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CompoundStrategy} from "./CompoundStrategy.sol";
import {PrezoptBridge} from "../bridge/PrezoptBridge.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract BaseCompoundReceiver is CompoundStrategy {
    using SafeTransferLib for IERC20;

    PrezoptBridge public bridge;
    uint32 public blockdagEid;
    address public blockdagStrategy;

    event AssetsReceived(uint256 amount, address indexed from);
    event YieldSent(uint256 amount, address indexed to);

    constructor(
        address _asset,
        address _comet,
        address _bridge,
        uint32 _blockdagEid,
        address _blockdagStrategy
    ) CompoundStrategy(_asset, _comet) {
        bridge = PrezoptBridge(_bridge);
        blockdagEid = _blockdagEid;
        blockdagStrategy = _blockdagStrategy;
    }

    function receiveAndInvest(uint256 amount) external {
        require(msg.sender == address(bridge), "Only bridge");
        
        SafeTransferLib.safeApprove(address(asset), address(comet), 0);
        SafeTransferLib.safeApprove(address(asset), address(comet), amount);
        comet.supply(address(asset), amount);
        
        emit AssetsReceived(amount, msg.sender);
    }

    function harvestAndBridge() external payable returns (uint256) {
        uint256 yield = comet.claim(address(this), address(this));
        
        if (yield > 0) {
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

    function emergencyWithdrawAndBridge(uint256 amount) external payable {
        require(msg.sender == address(bridge), "Only bridge");
        
        comet.withdraw(address(asset), amount);
        
        uint256 balance = asset.balanceOf(address(this));
        SafeTransferLib.safeApprove(address(asset), address(bridge), balance);
        
        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        bridge.bridgeToken{value: msg.value}(
            address(asset),
            balance,
            blockdagStrategy,
            blockdagEid,
            options
        );
    }
}