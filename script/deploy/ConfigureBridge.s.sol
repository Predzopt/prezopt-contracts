// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PrezoptBridge} from "src/bridge/PrezoptBridge.sol";

contract ConfigureBridge is Script {
    uint32 constant BLOCKDAG_EID = 40267;
    uint32 constant BASE_EID = 30184;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        
        address blockdagBridge = vm.envAddress("BLOCKDAG_BRIDGE");
        address baseBridge = vm.envAddress("BASE_BRIDGE");
        
        vm.startBroadcast(deployerKey);
        
        if (block.chainid == BLOCKDAG_EID) {
            _configureBlockDAG(blockdagBridge, baseBridge);
        } else if (block.chainid == BASE_EID) {
            _configureBase(baseBridge, blockdagBridge);
        }
        
        vm.stopBroadcast();
    }
    
    function _configureBlockDAG(address blockdagBridge, address baseBridge) internal {
        console.log("Configuring BlockDAG bridge...");
        
        PrezoptBridge bridge = PrezoptBridge(blockdagBridge);
        bridge.setPeerBridge(BASE_EID, baseBridge);
        
        console.log("Set Base peer:", baseBridge);
    }
    
    function _configureBase(address baseBridge, address blockdagBridge) internal {
        console.log("Configuring Base bridge...");
        
        PrezoptBridge bridge = PrezoptBridge(baseBridge);
        bridge.setPeerBridge(BLOCKDAG_EID, blockdagBridge);
        
        console.log("Set BlockDAG peer:", blockdagBridge);
    }
}