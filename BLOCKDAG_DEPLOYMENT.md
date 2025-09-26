# BlockDAG Deployment Guide

## Deployment

### BlockDAG Testnet
```bash
forge script script/deploy/DeployAll.s.sol --rpc-url blockdag_testnet --broadcast
```

### BlockDAG Mainnet
```bash
forge script script/deploy/DeployAll.s.sol --rpc-url blockdag --broadcast
```

## Testing
```bash
forge test --rpc-url blockdag_testnet
```