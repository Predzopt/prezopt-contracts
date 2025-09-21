// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PZTToken} from "../tokens/PZTToken.sol";

contract KeeperRewards {
    PZTToken public pzt;
    mapping(bytes32 => bool) public claimed;

    event RewardPaid(address indexed keeper, uint256 amount, bytes32 txHash);

    constructor(PZTToken _pzt) {
        pzt = _pzt;
    }

    function claim(address keeper, bytes32 txHash) external {
        require(!claimed[txHash], "Already claimed");
        claimed[txHash] = true;
        uint256 reward = 10 ** 18; // 1 $PZT — mock, should be dynamic
        pzt.mint(keeper, reward);
        emit RewardPaid(keeper, reward, txHash);
    }
}