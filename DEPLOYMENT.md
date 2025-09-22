# Deployment Guide

## Prerequisites

1. Set up environment variables in `.env`
2. Fund deployer wallet with native tokens on both chains
3. Ensure LayerZero endpoints are available

## Environment Setup

```bash
cp .env.example .env
# Edit .env with your values
```

Required variables:
- `PRIVATE_KEY` - Deployer private key
- `RPC_URL_BASE` - Base chain RPC
- `RPC_URL_BLOCKDAG` - BlockDAG chain RPC
- `USDC_ADDRESS` - USDC token address
- Protocol addresses on Base

## Deployment Steps

### 1. Deploy Base Chain Infrastructure
```bash
forge script script/deploy/DeployBridge.s.sol --rpc-url base --broadcast --verify
```

### 2. Deploy BlockDAG Infrastructure
```bash
forge script script/deploy/DeployBridge.s.sol --rpc-url blockdag --broadcast --verify
```

### 3. Configure Cross-Chain Connections
```bash
# Update .env with deployed bridge addresses
forge script script/deploy/ConfigureBridge.s.sol --rpc-url blockdag --broadcast
forge script script/deploy/ConfigureBridge.s.sol --rpc-url base --broadcast
```

### 4. Deploy Full Protocol (BlockDAG)
```bash
forge script script/deploy/DeployAll.s.sol --rpc-url blockdag --broadcast --verify
```

## Verification

Verify contracts on block explorers:
```bash
forge verify-contract <address> <contract> --chain-id <id> --etherscan-api-key <key>
```

## Usage Flow

1. Users deposit USDC to PrezoptVault on BlockDAG
2. ML signals trigger cross-chain rebalancing via CrossChainRebalanceExecutor
3. Assets bridge to Base for Aave/Compound yield farming
4. Yields automatically bridge back to BlockDAG
5. Users withdraw from BlockDAG vault with accumulated yields