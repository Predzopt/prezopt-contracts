# prezopt-contracts

Smart contracts for Prezopt Protocol — autonomous ML-driven yield optimizer with $PZT token.

Built with Foundry. Cross-chain deployment on BlockDAG + Base via LayerZero.

## Architecture

**BlockDAG (Main Chain):**
- PrezoptVault (ERC-4626) - User deposits/withdrawals
- CrossChainAaveStrategy - Bridges to Base Aave
- CrossChainCompoundStrategy - Bridges to Base Compound
- CrossChainRebalanceExecutor - ML-driven cross-chain rebalancing
- PZTToken (ERC-20) + PZTStaking + KeeperRewards
- Governance (Governor + Timelock)

**Base Chain (Yield Generation):**
- BaseAaveReceiver - Receives bridged assets, invests in Aave
- BaseCompoundReceiver - Receives bridged assets, invests in Compound
- Auto-harvest and bridge yields back to BlockDAG

**LayerZero Bridge:**
- Cross-chain asset transfers
- Automated yield bridging
- Emergency cross-chain withdrawals