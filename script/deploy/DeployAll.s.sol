// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PrezoptVault} from "src/vault/PrezoptVault.sol";
import {PZTToken} from "src/tokens/PZTToken.sol";
import {PZTStaking} from "src/staking/PZTStaking.sol";
import {KeeperRewards} from "src/rewards/KeeperRewards.sol";
import {RebalanceExecutor} from "src/executor/RebalanceExecutor.sol";
import {AaveStrategy} from "src/strategies/AaveStrategy.sol";
import {CompoundStrategy} from "src/strategies/CompoundStrategy.sol";
import {GovernorPrezopt} from "src/governance/GovernorPrezopt.sol";
import {TimelockController} from "src/governance/TimelockController.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20 as SolmateERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC20 as SoladyERC20} from "solady/src/tokens/ERC20.sol";
import {ERC20Votes} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Votes.sol";

contract DeployAll is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        address usdc = vm.envAddress("USDC_ADDRESS"); // Sepolia USDC

        // Deploy $PZT
        PZTToken pzt = new PZTToken();

        // Deploy Staking + KeeperRewards
        PZTStaking staking = new PZTStaking(ERC20(address(pzt)), ERC20(usdc));
        KeeperRewards keeperRewards = new KeeperRewards(pzt);

        // Deploy Vault
        PrezoptVault vault = new PrezoptVault(SolmateERC20(usdc), deployer, address(staking), address(keeperRewards));

        // Deploy Strategies (mock addresses for now)
        // AaveStrategy aaveStrategy = new AaveStrategy(usdc, deployer, deployer, deployer); // Abstract
        CompoundStrategy compoundStrategy = new CompoundStrategy(usdc, deployer);

        // Deploy DEX Aggregator mock
        AggregatorMock dex = new AggregatorMock(ERC20(usdc));

        // Deploy Executor
        RebalanceExecutor executor = new RebalanceExecutor(SoladyERC20(usdc), address(vault), deployer, deployer, address(dex));

        // Deploy Timelock + Governor
        TimelockController timelock = new TimelockController();
        timelock.initialize(deployer, new address[](0), new address[](0), 2 days);

        GovernorPrezopt governor = new GovernorPrezopt();
        governor.initialize(ERC20Votes(address(pzt)), timelock, 5); // 5% quorum

        vm.stopBroadcast();

        // Log all addresses
        console.log("PZT:", address(pzt));
        console.log("Vault:", address(vault));
        console.log("Executor:", address(executor));
        // console.log("AaveStrategy:", address(aaveStrategy));
        console.log("CompoundStrategy:", address(compoundStrategy));
        console.log("Staking:", address(staking));
        console.log("KeeperRewards:", address(keeperRewards));
        console.log("Timelock:", address(timelock));
        console.log("Governor:", address(governor));
    }
}

contract AggregatorMock {
    ERC20 public asset;
    constructor(ERC20 _asset) { asset = _asset; }
    function swap(address, address, uint256 amountIn, uint256) external pure returns (uint256) { return amountIn; } // no slippage
}