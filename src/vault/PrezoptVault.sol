// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "solmate/src/tokens/ERC4626.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract PrezoptVault is ERC4626 {
    using SafeTransferLib for ERC20;

    uint256 public constant MANAGEMENT_FEE_BPS = 5;
    address public treasury;
    address public staking;
    address public keeperRewards;

    event FeeDistributed(uint256 totalFee, uint256 toStakers, uint256 toTreasury, uint256 toKeepers);

    constructor(ERC20 _asset, address _treasury, address _staking, address _keeperRewards)
        ERC4626(_asset, string.concat("Prezopt ", _asset.name()), string.concat("py", _asset.symbol()))
    {
        treasury = _treasury;
        staking = _staking;
        keeperRewards = _keeperRewards;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
        _collectFee(assets);
    }

    function _collectFee(uint256 assets) internal {
        uint256 fee = (assets * MANAGEMENT_FEE_BPS) / 10000;
        if (fee > 0) {
            uint256 toStakers = (fee * 60) / 100;
            uint256 toTreasury = (fee * 30) / 100;
            uint256 toKeepers = fee - toStakers - toTreasury;

            asset.safeTransfer(staking, toStakers);
            asset.safeTransfer(treasury, toTreasury);
            asset.safeTransfer(keeperRewards, toKeepers);

            emit FeeDistributed(fee, toStakers, toTreasury, toKeepers);
        }
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}