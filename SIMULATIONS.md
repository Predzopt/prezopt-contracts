# Simulation Contracts

Mock protocols for testing Prezopt Protocol on BlockDAG testnet.

## Mock Tokens

**Base Assets:**
- **MockUSDC** - 6 decimals, mintable USDC for testing
- **MockUSDT** - 6 decimals, mintable USDT for testing
- **MockWETH** - 18 decimals, mintable WETH with deposit/withdraw

**Reward Tokens:**
- **MockAAVE** - Aave reward token
- **MockCOMP** - Compound reward token  
- **MockCRV** - Curve reward token
- **MockYFI** - Yearn reward token

## Mock Strategies

### MockAaveStrategy
- Base APY: 5%
- Reward APY: 2% (AAVE tokens)
- Simulates Aave V3 lending

### MockCompoundStrategy  
- Base APY: 4%
- Reward APY: 3% (COMP tokens)
- Simulates Compound V3 lending

### MockCurveStrategy
- Base APY: 3% 
- Reward APY: 4% (CRV tokens)
- Includes 0.1% slippage on entry/exit
- Simulates Curve 3pool LP

### MockYearnStrategy
- Base APY: 6%
- Reward APY: 1% (YFI tokens)
- 2% management fee
- Simulates Yearn vault

## Deployment

```bash
forge script script/deploy/DeploySimulations.s.sol --rpc-url blockdag_testnet --broadcast
```

## Testing

```bash
forge test --match-contract SimulationsTest -vv
```

## Usage

All mock strategies implement `IStrategy` interface and are compatible with PrezoptVault and RebalanceExecutor. They provide realistic yield accrual, reward emissions, and protocol-specific features for ML model training and keeper bot testing.