// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}

abstract contract AaveStrategy is IStrategy {
    using SafeTransferLib for IERC20;

    IERC20 public asset;
    IAavePool public pool;
    IERC20 public rewardToken; // stkAAVE
    address public rewardsController;

    constructor(address _asset, address _pool, address _rewardsController, address _rewardToken) {
        asset = IERC20(_asset);
        pool = IAavePool(_pool);
        rewardsController = _rewardsController;
        rewardToken = IERC20(_rewardToken);
    }

    function invest(uint256 amount) external payable override {
        SafeTransferLib.safeApprove(address(asset), address(pool), 0);
        SafeTransferLib.safeApprove(address(asset), address(pool), amount);
        pool.supply(address(asset), amount, address(this), 0);
    }

    function withdraw(uint256 amount, address to) external returns (uint256) {
        return pool.withdraw(address(asset), amount, to);
    }

    function harvest() external override returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = address(asset);
        uint256 claimed = pool.claimRewards(assets, type(uint256).max, address(this));
        if (claimed > 0) {
            // TODO: Swap rewardToken to asset via DEX (simplified for now)
            return claimed; // mock profit
        }
        return 0;
    }

    function estimatedTotalAssets() external view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}