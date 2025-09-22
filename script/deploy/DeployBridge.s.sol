// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PrezoptBridge} from "src/bridge/PrezoptBridge.sol";
import {CrossChainAaveStrategy} from "src/strategies/CrossChainAaveStrategy.sol";
import {CrossChainCompoundStrategy} from "src/strategies/CrossChainCompoundStrategy.sol";
import {BaseAaveReceiver} from "src/strategies/BaseAaveReceiver.sol";
import {BaseCompoundReceiver} from "src/strategies/BaseCompoundReceiver.sol";
import {CrossChainRebalanceExecutor} from "src/executor/CrossChainRebalanceExecutor.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ERC20 as SoladyERC20} from "solady/src/tokens/ERC20.sol";

contract DeployBridge is Script {
    // LayerZero Endpoint addresses
    address constant BLOCKDAG_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c; // Placeholder
    address constant BASE_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    
    // Chain IDs (LayerZero EIDs)
    uint32 constant BLOCKDAG_EID = 40267; // Placeholder
    uint32 constant BASE_EID = 30184;
    
    // Protocol addresses on Base
    address constant BASE_AAVE_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant BASE_AAVE_REWARDS = 0xf9cc4F0D883F1a1eb2c253bdb46c254Ca51E1F44;
    address constant BASE_AAVE_TOKEN = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;
    address constant BASE_COMPOUND_COMET = 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address usdc = vm.envAddress("USDC_ADDRESS");
        
        vm.startBroadcast(deployerKey);
        
        if (block.chainid == BLOCKDAG_EID) {
            _deployBlockDAG(deployer, usdc);
        } else if (block.chainid == BASE_EID) {
            _deployBase(deployer, usdc);
        } else {
            revert("Unsupported chain");
        }
        
        vm.stopBroadcast();
    }
    
    function _deployBlockDAG(address deployer, address usdc) internal {
        console.log("Deploying on BlockDAG...");
        
        // Deploy Bridge
        PrezoptBridge bridge = new PrezoptBridge(BLOCKDAG_ENDPOINT, deployer);
        console.log("Bridge:", address(bridge));
        
        // Deploy Cross-chain Strategies
        CrossChainAaveStrategy aaveStrategy = new CrossChainAaveStrategy(
            usdc,
            address(bridge),
            BASE_EID,
            address(0) // Will be set after Base deployment
        );
        
        CrossChainCompoundStrategy compoundStrategy = new CrossChainCompoundStrategy(
            usdc,
            address(bridge),
            BASE_EID,
            address(0) // Will be set after Base deployment
        );
        
        // Deploy Cross-chain Executor
        CrossChainRebalanceExecutor executor = new CrossChainRebalanceExecutor(
            SoladyERC20(usdc),
            deployer, // vault placeholder
            deployer, // keeper
            deployer, // mlSigner
            address(bridge)
        );
        
        // Configure bridge
        bridge.setSupportedToken(usdc, true);
        
        console.log("CrossChainAaveStrategy:", address(aaveStrategy));
        console.log("CrossChainCompoundStrategy:", address(compoundStrategy));
        console.log("CrossChainExecutor:", address(executor));
    }
    
    function _deployBase(address deployer, address usdc) internal {
        console.log("Deploying on Base...");
        
        // Deploy Bridge
        PrezoptBridge bridge = new PrezoptBridge(BASE_ENDPOINT, deployer);
        console.log("Bridge:", address(bridge));
        
        // Deploy Base Receivers
        BaseAaveReceiver aaveReceiver = new BaseAaveReceiver(
            usdc,
            BASE_AAVE_POOL,
            BASE_AAVE_REWARDS,
            BASE_AAVE_TOKEN,
            address(bridge),
            BLOCKDAG_EID,
            address(0) // Will be set after BlockDAG deployment
        );
        
        BaseCompoundReceiver compoundReceiver = new BaseCompoundReceiver(
            usdc,
            BASE_COMPOUND_COMET,
            address(bridge),
            BLOCKDAG_EID,
            address(0) // Will be set after BlockDAG deployment
        );
        
        // Configure bridge
        bridge.setSupportedToken(usdc, true);
        
        console.log("BaseAaveReceiver:", address(aaveReceiver));
        console.log("BaseCompoundReceiver:", address(compoundReceiver));
    }
}