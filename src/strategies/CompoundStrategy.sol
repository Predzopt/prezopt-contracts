// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function claim(address from, address to) external returns (uint256);
}

contract CompoundStrategy is IStrategy {
    using SafeTransferLib for IERC20;

    IERC20 public asset;
    IComet public comet;

    constructor(address _asset, address _comet) {
        asset = IERC20(_asset);
        comet = IComet(_comet);
    }

    function invest(uint256 amount) external override {
        SafeTransferLib.safeApprove(address(asset), address(comet), 0);
        SafeTransferLib.safeApprove(address(asset), address(comet), amount);
        comet.supply(address(asset), amount);
    }

    function withdraw(uint256 amount) external override {
        comet.withdraw(address(asset), amount);
    }

    function harvest() external override returns (uint256) {
        uint256 claimed = comet.claim(address(this), address(this));
        if (claimed > 0) {
            // TODO: Swap COMP to asset (simplified)
            return claimed; // mock
        }
        return 0;
    }

    function estimatedTotalAssets() external view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}