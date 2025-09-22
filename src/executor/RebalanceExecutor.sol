// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRebalanceExecutor} from "../interfaces/IRebalanceExecutor.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "openzeppelin-contracts/utils/cryptography/EIP712.sol";

interface IAggregator {
    function swap(address fromToken, address toToken, uint256 amountIn, uint256 minAmountOut) external returns (uint256);
}

contract RebalanceExecutor is IRebalanceExecutor, EIP712 {
    using ECDSA for bytes32;
    using SafeTransferLib for ERC20;

    ERC20 public asset;
    address public vault;
    address public keeper;
    address public mlSigner;
    IAggregator public dexAggregator;
    uint256 public constant MAX_AGE = 300;

    bytes32 private constant REBALANCE_TYPEHASH =
        keccak256("RebalanceSignal(address fromStrategy,address toStrategy,uint256 amount,uint256 minOutput,uint256 expectedNetGain,uint256 timestamp)");

    constructor(ERC20 _asset, address _vault, address _keeper, address _mlSigner, address _dexAggregator)
        EIP712("PrezoptRebalance", "1")
    {
        asset = _asset;
        vault = _vault;
        keeper = _keeper;
        mlSigner = _mlSigner;
        dexAggregator = IAggregator(_dexAggregator);
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

        IStrategy(signal.fromStrategy).withdraw(signal.amount);
        uint256 swapped = dexAggregator.swap(address(asset), address(asset), signal.amount, signal.minOutput);
        IStrategy(signal.toStrategy).invest(swapped);

        emit Rebalanced(signal.fromStrategy, signal.toStrategy, signal.amount, swapped - signal.amount);
    }

    event Rebalanced(address indexed from, address indexed to, uint256 amount, uint256 profit);
}