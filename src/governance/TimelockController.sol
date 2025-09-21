// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockControllerUpgradeable} from "openzeppelin-contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract TimelockController is TimelockControllerUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address[] memory proposers, address[] memory executors, uint256 minDelay) external initializer {
        __TimelockController_init(minDelay, proposers, executors, admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}