# Prezopt Subgraph

GraphQL API for querying Prezopt Protocol data on BlockDAG.

## Setup

```bash
cd subgraph
npm install
```

## Configuration

Contract addresses are already configured for BlockDAG testnet:
- **Vault:** `0x697dcBeED2eF796D278875B697A066139710d4fa`
- **Staking:** `0x303A47b107bD6028E3F0E6c784501888251deB86`
- **Executor:** `0xA57309A9DB3870ac638490B368B6B9f5443eC623`
- **PZT Token:** `0x78e965134D30B41D5657526a7dd0aB8F20604B29`

## Build & Deploy

```bash
# Copy ABIs from contracts
../scripts/copy-abis.bat

# Generate types
npm run codegen

# Build subgraph
npm run build

# Deploy to The Graph Studio
npm run deploy
```

## Example Queries

### Get Vault Stats
```graphql
{
  vault(id: "vault") {
    totalAssets
    totalSupply
    sharePrice
    depositCount
    withdrawalCount
  }
}
```

### Get User Data
```graphql
{
  user(id: "0x...") {
    vaultShares
    vaultAssets
    stakedPZT
    totalDeposited
    totalWithdrawn
  }
}
```

### Get Recent Deposits
```graphql
{
  deposits(first: 10, orderBy: timestamp, orderDirection: desc) {
    user {
      id
    }
    assets
    shares
    timestamp
  }
}
```

### Get Rebalance History
```graphql
{
  rebalances(first: 20, orderBy: timestamp, orderDirection: desc) {
    fromStrategy
    toStrategy
    amount
    profit
    timestamp
  }
}
```

### Get Top Stakers
```graphql
{
  stakingUsers(first: 10, orderBy: stakedAmount, orderDirection: desc) {
    id
    stakedAmount
    rewardsClaimed
  }
}
```