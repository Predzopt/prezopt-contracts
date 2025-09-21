// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PrezoptVault} from "../../src/vault/PrezoptVault.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockPrezoptVault is PrezoptVault {
    constructor(ERC20 asset_, address treasury, address staking, address keeperRewards)
        PrezoptVault(asset_, treasury, staking, keeperRewards)
    {
    }
}