// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockPrezoptVault} from "../mocks/MockPrezoptVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract VaultTest is Test {
    MockPrezoptVault vault;
    MockERC20 usdc;

    function setUp() public {
        usdc = new MockERC20("Mock USDC", "USDC", 6);
        vault = new MockPrezoptVault(ERC20(address(usdc)), address(1), address(2), address(3));
        usdc.mint(address(this), 100_000_000e6);
    }

    function testDepositCollectsFee() public {
        usdc.approve(address(vault), type(uint256).max);
        uint256 assets = 10_000e6; // $10,000 USDC

        vm.prank(address(0x1234));
        vault.deposit(assets, address(0x1234));

        uint256 fee = (assets * 5) / 10000; // 5 bps
        assertEq(usdc.balanceOf(address(1)), (fee * 60) / 100); // stakers
        assertEq(usdc.balanceOf(address(2)), (fee * 30) / 100); // treasury
        assertEq(usdc.balanceOf(address(3)), fee - ((fee * 60) / 100) - ((fee * 30) / 100)); // keepers
    }
}