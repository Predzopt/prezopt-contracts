# LayerZero Bridge Deployment Guide

## Prerequisites

1. LayerZero endpoints deployed on both chains
2. USDC contracts on both chains
3. Aave and Compound protocols on Base chain

## Environment Variables

```bash
# Common
PRIVATE_KEY=your_private_key
USDC_ADDRESS=usdc_contract_address

# LayerZero
LZ_ENDPOINT=layerzero_endpoint_address
BASE_EID=30184
BLOCKDAG_EID=40267

# Base Protocol Addresses
BASE_AAVE_RECEIVER=deployed_base_aave_receiver
BASE_COMPOUND_RECEIVER=deployed_base_compound_receiver

# Bridge Addresses (after deployment)
BLOCKDAG_BRIDGE=deployed_blockdag_bridge
BASE_BRIDGE=deployed_base_bridge
```

## Deployment Steps

### 1. Deploy on Base Chain
```bash
forge script script/deploy/DeployBridge.s.sol --rpc-url $BASE_RPC --broadcast
```

### 2. Deploy on BlockDAG Chain
```bash
forge script script/deploy/DeployBridge.s.sol --rpc-url $BLOCKDAG_RPC --broadcast
```

### 3. Configure Cross-Chain Connections
```bash
# On BlockDAG
forge script script/deploy/ConfigureBridge.s.sol --rpc-url $BLOCKDAG_RPC --broadcast

# On Base
forge script script/deploy/ConfigureBridge.s.sol --rpc-url $BASE_RPC --broadcast
```

### 4. Deploy Full Protocol (BlockDAG)
```bash
forge script script/deploy/DeployAll.s.sol --rpc-url $BLOCKDAG_RPC --broadcast
```

## Architecture

- **BlockDAG**: Main vault, cross-chain strategies, bridge
- **Base**: Protocol receivers (Aave/Compound), bridge
- **LayerZero**: Cross-chain messaging and asset bridging

## Usage

1. Users deposit USDC to PrezoptVault on BlockDAG
2. ML signals trigger cross-chain rebalancing
3. Assets bridge to Base for Aave/Compound yield
4. Yields bridge back to BlockDAG
5. Users withdraw from BlockDAG vault