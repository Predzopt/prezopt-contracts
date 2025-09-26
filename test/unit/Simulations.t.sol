// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockUSDC} from "src/simulations/tokens/MockUSDC.sol";
import {MockAAVE, MockCOMP, MockCRV, MockYFI} from "src/simulations/tokens/MockRewardTokens.sol";
import {MockAaveStrategy} from "src/simulations/strategies/MockAaveStrategy.sol";
import {MockCompoundStrategy} from "src/simulations/strategies/MockCompoundStrategy.sol";
import {MockCurveStrategy} from "src/simulations/strategies/MockCurveStrategy.sol";
import {MockYearnStrategy} from "src/simulations/strategies/MockYearnStrategy.sol";

contract SimulationsTest is Test {
    MockUSDC usdc;
    MockAAVE aave;
    MockCOMP comp;
    MockCRV crv;
    MockYFI yfi;
    
    MockAaveStrategy aaveStrategy;
    MockCompoundStrategy compoundStrategy;
    MockCurveStrategy curveStrategy;
    MockYearnStrategy yearnStrategy;
    
    address user = makeAddr("user");
    uint256 depositAmount = 1000 * 10**6; // 1000 USDC

    function setUp() public {
        // Deploy tokens
        usdc = new MockUSDC();
        aave = new MockAAVE();
        comp = new MockCOMP();
        crv = new MockCRV();
        yfi = new MockYFI();
        
        // Deploy strategies
        aaveStrategy = new MockAaveStrategy(address(usdc), address(aave));
        compoundStrategy = new MockCompoundStrategy(address(usdc), address(comp));
        curveStrategy = new MockCurveStrategy(address(usdc), address(crv));
        yearnStrategy = new MockYearnStrategy(address(usdc), address(yfi));
        
        // Setup user with USDC
        usdc.mint(user, depositAmount * 10);
    }

    function testAaveStrategyYieldAccrual() public {
        vm.startPrank(user);
        
        usdc.approve(address(aaveStrategy), depositAmount);
        aaveStrategy.invest(depositAmount);
        
        uint256 initialAssets = aaveStrategy.estimatedTotalAssets();
        
        // Fast forward 30 days
        vm.warp(block.timestamp + 30 days);
        
        uint256 finalAssets = aaveStrategy.estimatedTotalAssets();
        
        // Should have accrued ~5% APY for 30 days
        uint256 expectedYield = (depositAmount * 500 * 30 days) / (365 days * 10000);
        assertApproxEqRel(finalAssets - initialAssets, expectedYield, 0.01e18); // 1% tolerance
        
        vm.stopPrank();
    }

    function testCompoundStrategyRewards() public {
        vm.startPrank(user);
        
        usdc.approve(address(compoundStrategy), depositAmount);
        compoundStrategy.invest(depositAmount);
        
        // Fast forward and harvest
        vm.warp(block.timestamp + 7 days);
        uint256 rewards = compoundStrategy.harvest();
        
        assertGt(rewards, 0, "Should have harvested rewards");
        assertGt(comp.balanceOf(address(compoundStrategy)), 0, "Should have COMP tokens");
        
        vm.stopPrank();
    }

    function testCurveStrategySlippage() public {
        vm.startPrank(user);
        
        usdc.approve(address(curveStrategy), depositAmount);
        
        uint256 balanceBefore = usdc.balanceOf(user);
        curveStrategy.invest(depositAmount);
        
        // Withdraw immediately to test slippage
        curveStrategy.withdraw(depositAmount);
        uint256 balanceAfter = usdc.balanceOf(user);
        
        // Should have lost some to slippage (0.1% on entry + 0.1% on exit)
        uint256 expectedSlippage = (depositAmount * 20) / 10000; // 0.2% total
        assertApproxEqAbs(balanceBefore - balanceAfter, expectedSlippage, depositAmount / 1000);
        
        vm.stopPrank();
    }

    function testYearnStrategyManagementFees() public {
        vm.startPrank(user);
        
        usdc.approve(address(yearnStrategy), depositAmount);
        yearnStrategy.invest(depositAmount);
        
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);
        
        uint256 finalAssets = yearnStrategy.estimatedTotalAssets();
        
        // Should have ~4% net APY after 2% management fee (6% gross - 2% fee)
        uint256 expectedNetYield = (depositAmount * 400) / 10000; // 4% net
        assertApproxEqRel(finalAssets - depositAmount, expectedNetYield, 0.05e18); // 5% tolerance
        
        vm.stopPrank();
    }

    function testStrategyAPYComparison() public {
        // Test that strategies have different APYs for ML model training
        uint256 aaveAPY = aaveStrategy.getCurrentAPY();
        uint256 compoundAPY = compoundStrategy.getCurrentAPY();
        uint256 curveAPY = curveStrategy.getCurrentAPY();
        uint256 yearnAPY = yearnStrategy.getCurrentAPY();
        
        console.log("Aave APY:", aaveAPY);
        console.log("Compound APY:", compoundAPY);
        console.log("Curve APY:", curveAPY);
        console.log("Yearn APY:", yearnAPY);
        
        // All should be different for realistic simulation
        assertTrue(aaveAPY != compoundAPY);
        assertTrue(compoundAPY != curveAPY);
        assertTrue(curveAPY != yearnAPY);
    }
}