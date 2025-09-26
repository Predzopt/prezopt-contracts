// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MockUSDC} from "src/simulations/tokens/MockUSDC.sol";
import {MockUSDT} from "src/simulations/tokens/MockUSDT.sol";
import {MockWETH} from "src/simulations/tokens/MockWETH.sol";
import {MockAAVE, MockCOMP, MockCRV, MockYFI} from "src/simulations/tokens/MockRewardTokens.sol";
import {MockAaveStrategy} from "src/simulations/strategies/MockAaveStrategy.sol";
import {MockCompoundStrategy} from "src/simulations/strategies/MockCompoundStrategy.sol";
import {MockCurveStrategy} from "src/simulations/strategies/MockCurveStrategy.sol";
import {MockYearnStrategy} from "src/simulations/strategies/MockYearnStrategy.sol";

contract DeploySimulations is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        vm.startBroadcast(deployerKey);
        
        console.log("Deploying simulation contracts...");
        console.log("Deployer:", deployer);
        
        // Deploy mock tokens
        MockUSDC usdc = new MockUSDC();
        MockUSDT usdt = new MockUSDT();
        MockWETH weth = new MockWETH();
        MockAAVE aave = new MockAAVE();
        MockCOMP comp = new MockCOMP();
        MockCRV crv = new MockCRV();
        MockYFI yfi = new MockYFI();
        
        console.log("Mock Tokens:");
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));
        console.log("WETH:", address(weth));
        console.log("AAVE:", address(aave));
        console.log("COMP:", address(comp));
        console.log("CRV:", address(crv));
        console.log("YFI:", address(yfi));
        
        // Deploy mock strategies
        MockAaveStrategy aaveStrategy = new MockAaveStrategy(address(usdc), address(aave));
        MockCompoundStrategy compoundStrategy = new MockCompoundStrategy(address(usdc), address(comp));
        MockCurveStrategy curveStrategy = new MockCurveStrategy(address(usdc), address(crv));
        MockYearnStrategy yearnStrategy = new MockYearnStrategy(address(usdc), address(yfi));
        
        console.log("Mock Strategies:");
        console.log("Aave Strategy:", address(aaveStrategy));
        console.log("Compound Strategy:", address(compoundStrategy));
        console.log("Curve Strategy:", address(curveStrategy));
        console.log("Yearn Strategy:", address(yearnStrategy));
        
        // Mint some tokens to deployer for testing
        usdc.mint(deployer, 100000 * 10**6); // 100k USDC
        usdt.mint(deployer, 100000 * 10**6); // 100k USDT
        weth.mint(deployer, 1000 * 10**18); // 1k WETH
        
        console.log("Simulation deployment complete!");
        
        vm.stopBroadcast();
    }
}