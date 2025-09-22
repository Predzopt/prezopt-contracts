// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRebalanceExecutor} from "../interfaces/IRebalanceExecutor.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {PrezoptBridge} from "../bridge/PrezoptBridge.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "openzeppelin-contracts/utils/cryptography/EIP712.sol";

contract CrossChainRebalanceExecutor is IRebalanceExecutor, EIP712 {
    using ECDSA for bytes32;
    using SafeTransferLib for ERC20;

    ERC20 public asset;
    address public vault;
    address public keeper;
    address public mlSigner;
    PrezoptBridge public bridge;
    uint256 public constant MAX_AGE = 300;

    mapping(address => bool) public isCrossChainStrategy;
    mapping(address => uint32) public strategyChainId;

    bytes32 private constant REBALANCE_TYPEHASH =
        keccak256("RebalanceSignal(address fromStrategy,address toStrategy,uint256 amount,uint256 minOutput,uint256 expectedNetGain,uint256 timestamp)");

    event CrossChainRebalanceInitiated(address indexed from, address indexed to, uint256 amount, uint32 chainId);

    constructor(
        ERC20 _asset,
        address _vault,
        address _keeper,
        address _mlSigner,
        address _bridge
    ) EIP712("PrezoptCrossChainRebalance", "1") {
        asset = _asset;
        vault = _vault;
        keeper = _keeper;
        mlSigner = _mlSigner;
        bridge = PrezoptBridge(_bridge);
    }

    function setCrossChainStrategy(address strategy, bool isCrossChain, uint32 chainId) external {
        require(msg.sender == vault, "Only vault");
        isCrossChainStrategy[strategy] = isCrossChain;
        strategyChainId[strategy] = chainId;
    }

    function rebalance(RebalanceSignal calldata signal) external payable {
        require(msg.sender == keeper, "Not keeper");
        require(block.timestamp - signal.timestamp <= MAX_AGE, "Stale");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REBALANCE_TYPEHASH,
                    signal.fromStrategy,
                    signal.toStrategy,
                    signal.amount,
                    signal.minOutput,
                    signal.expectedNetGain,
                    signal.timestamp
                )
            )
        );

        address recovered = digest.recover(signal.signature);
        require(recovered == mlSigner, "Invalid sig");

        bool fromCrossChain = isCrossChainStrategy[signal.fromStrategy];
        bool toCrossChain = isCrossChainStrategy[signal.toStrategy];

        if (!fromCrossChain && !toCrossChain) {
            // Local rebalance
            _localRebalance(signal);
        } else if (fromCrossChain && !toCrossChain) {
            // Cross-chain to local
            _crossChainToLocal(signal);
        } else if (!fromCrossChain && toCrossChain) {
            // Local to cross-chain
            _localToCrossChain(signal);
        } else {
            // Cross-chain to cross-chain (complex, simplified for now)
            revert("Cross-chain to cross-chain not supported");
        }
    }

    function _localRebalance(RebalanceSignal calldata signal) internal {
        IStrategy(signal.fromStrategy).withdraw(signal.amount);
        IStrategy(signal.toStrategy).invest(signal.amount);
        emit Rebalanced(signal.fromStrategy, signal.toStrategy, signal.amount, 0);
    }

    function _crossChainToLocal(RebalanceSignal calldata signal) internal {
        // This would require coordination with cross-chain strategy
        // For now, emit event for off-chain coordination
        emit CrossChainRebalanceInitiated(
            signal.fromStrategy,
            signal.toStrategy,
            signal.amount,
            strategyChainId[signal.fromStrategy]
        );
    }

    function _localToCrossChain(RebalanceSignal calldata signal) internal {
        IStrategy(signal.fromStrategy).withdraw(signal.amount);
        
        SafeTransferLib.safeApprove(address(asset), address(bridge), signal.amount);
        
        bytes memory options = abi.encodePacked(uint16(1), uint128(200000));
        bridge.bridgeToken{value: msg.value}(
            address(asset),
            signal.amount,
            signal.toStrategy,
            strategyChainId[signal.toStrategy],
            options
        );

        emit CrossChainRebalanceInitiated(
            signal.fromStrategy,
            signal.toStrategy,
            signal.amount,
            strategyChainId[signal.toStrategy]
        );
    }

    event Rebalanced(address indexed from, address indexed to, uint256 amount, uint256 profit);
}