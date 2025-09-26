# Subgraph Frontend Integration

## Setup

```bash
npm install @apollo/client graphql
```

## Apollo Client Configuration

```typescript
// apollo-client.ts
import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client';

const httpLink = createHttpLink({
  uri: 'https://api.studio.thegraph.com/query/prezopt-protocol/subgraph',
});

export const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
});
```

## GraphQL Queries

```typescript
// queries.ts
import { gql } from '@apollo/client';

export const GET_VAULT_STATS = gql`
  query GetVaultStats {
    vault(id: "vault") {
      totalAssets
      totalSupply
      sharePrice
      depositCount
      withdrawalCount
      updatedAt
    }
  }
`;

export const GET_USER_PORTFOLIO = gql`
  query GetUserPortfolio($userAddress: String!) {
    user(id: $userAddress) {
      vaultShares
      vaultAssets
      totalDeposited
      totalWithdrawn
      depositCount
      withdrawalCount
    }
    stakingUser(id: $userAddress) {
      stakedAmount
      rewardsClaimed
    }
  }
`;

export const GET_RECENT_ACTIVITY = gql`
  query GetRecentActivity($first: Int = 10) {
    deposits(first: $first, orderBy: timestamp, orderDirection: desc) {
      id
      user { id }
      assets
      shares
      timestamp
      transactionHash
    }
    withdrawals(first: $first, orderBy: timestamp, orderDirection: desc) {
      id
      user { id }
      assets
      shares
      timestamp
      transactionHash
    }
  }
`;

export const GET_REBALANCE_HISTORY = gql`
  query GetRebalanceHistory($first: Int = 20) {
    rebalances(first: $first, orderBy: timestamp, orderDirection: desc) {
      fromStrategy
      toStrategy
      amount
      profit
      timestamp
    }
  }
`;
```

## React Hooks

```typescript
// hooks/useSubgraph.ts
import { useQuery } from '@apollo/client';
import { GET_VAULT_STATS, GET_USER_PORTFOLIO, GET_RECENT_ACTIVITY } from '../queries';

export function useVaultStats() {
  const { data, loading, error } = useQuery(GET_VAULT_STATS, {
    pollInterval: 30000, // Poll every 30 seconds
  });

  return {
    vaultStats: data?.vault,
    loading,
    error,
  };
}

export function useUserPortfolio(userAddress: string) {
  const { data, loading, error } = useQuery(GET_USER_PORTFOLIO, {
    variables: { userAddress: userAddress.toLowerCase() },
    skip: !userAddress,
    pollInterval: 30000,
  });

  return {
    user: data?.user,
    stakingUser: data?.stakingUser,
    loading,
    error,
  };
}

export function useRecentActivity() {
  const { data, loading, error } = useQuery(GET_RECENT_ACTIVITY, {
    pollInterval: 10000, // Poll every 10 seconds for activity
  });

  return {
    deposits: data?.deposits || [],
    withdrawals: data?.withdrawals || [],
    loading,
    error,
  };
}
```

## React Components

```typescript
// components/VaultStats.tsx
import React from 'react';
import { useVaultStats } from '../hooks/useSubgraph';
import { formatUnits } from 'ethers/lib/utils';

export function VaultStats() {
  const { vaultStats, loading, error } = useVaultStats();

  if (loading) return <div>Loading vault stats...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!vaultStats) return <div>No vault data</div>;

  return (
    <div className="vault-stats">
      <h2>Vault Statistics</h2>
      <div className="stats-grid">
        <div>
          <label>Total Assets</label>
          <span>{formatUnits(vaultStats.totalAssets, 6)} USDC</span>
        </div>
        <div>
          <label>Total Supply</label>
          <span>{formatUnits(vaultStats.totalSupply, 18)} Shares</span>
        </div>
        <div>
          <label>Share Price</label>
          <span>{parseFloat(vaultStats.sharePrice).toFixed(4)} USDC</span>
        </div>
        <div>
          <label>Total Deposits</label>
          <span>{vaultStats.depositCount}</span>
        </div>
      </div>
    </div>
  );
}
```

```typescript
// components/UserPortfolio.tsx
import React from 'react';
import { useUserPortfolio } from '../hooks/useSubgraph';
import { formatUnits } from 'ethers/lib/utils';

interface Props {
  userAddress: string;
}

export function UserPortfolio({ userAddress }: Props) {
  const { user, stakingUser, loading, error } = useUserPortfolio(userAddress);

  if (loading) return <div>Loading portfolio...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div className="user-portfolio">
      <h2>Your Portfolio</h2>
      
      <div className="vault-position">
        <h3>Vault Position</h3>
        <p>Assets: {user ? formatUnits(user.vaultAssets, 6) : '0'} USDC</p>
        <p>Shares: {user ? formatUnits(user.vaultShares, 18) : '0'}</p>
        <p>Total Deposited: {user ? formatUnits(user.totalDeposited, 6) : '0'} USDC</p>
      </div>

      <div className="staking-position">
        <h3>Staking Position</h3>
        <p>Staked PZT: {stakingUser ? formatUnits(stakingUser.stakedAmount, 18) : '0'}</p>
        <p>Rewards Claimed: {stakingUser ? formatUnits(stakingUser.rewardsClaimed, 6) : '0'} USDC</p>
      </div>
    </div>
  );
}
```

```typescript
// components/ActivityFeed.tsx
import React from 'react';
import { useRecentActivity } from '../hooks/useSubgraph';
import { formatUnits } from 'ethers/lib/utils';

export function ActivityFeed() {
  const { deposits, withdrawals, loading, error } = useRecentActivity();

  if (loading) return <div>Loading activity...</div>;
  if (error) return <div>Error: {error.message}</div>;

  const allActivity = [
    ...deposits.map(d => ({ ...d, type: 'deposit' })),
    ...withdrawals.map(w => ({ ...w, type: 'withdrawal' }))
  ].sort((a, b) => parseInt(b.timestamp) - parseInt(a.timestamp));

  return (
    <div className="activity-feed">
      <h2>Recent Activity</h2>
      <div className="activity-list">
        {allActivity.slice(0, 10).map((activity) => (
          <div key={activity.id} className={`activity-item ${activity.type}`}>
            <div className="activity-type">
              {activity.type === 'deposit' ? '📈' : '📉'} {activity.type}
            </div>
            <div className="activity-details">
              <span>{formatUnits(activity.assets, 6)} USDC</span>
              <span>{activity.user.id.slice(0, 6)}...{activity.user.id.slice(-4)}</span>
              <span>{new Date(parseInt(activity.timestamp) * 1000).toLocaleString()}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

## App Integration

```typescript
// App.tsx
import React from 'react';
import { ApolloProvider } from '@apollo/client';
import { client } from './apollo-client';
import { VaultStats } from './components/VaultStats';
import { UserPortfolio } from './components/UserPortfolio';
import { ActivityFeed } from './components/ActivityFeed';

function App() {
  const [userAddress, setUserAddress] = React.useState('');

  return (
    <ApolloProvider client={client}>
      <div className="app">
        <h1>Prezopt Protocol</h1>
        
        <VaultStats />
        
        {userAddress && <UserPortfolio userAddress={userAddress} />}
        
        <ActivityFeed />
      </div>
    </ApolloProvider>
  );
}

export default App;
```

## Data Formatting Utilities

```typescript
// utils/format.ts
import { formatUnits } from 'ethers/lib/utils';

export function formatUSDC(amount: string): string {
  return parseFloat(formatUnits(amount, 6)).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

export function formatPZT(amount: string): string {
  return parseFloat(formatUnits(amount, 18)).toLocaleString(undefined, {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  });
}

export function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatTimestamp(timestamp: string): string {
  return new Date(parseInt(timestamp) * 1000).toLocaleString();
}
```

## Real-time Updates

```typescript
// hooks/useRealTimeData.ts
import { useEffect, useState } from 'react';
import { useQuery } from '@apollo/client';

export function useRealTimeVaultStats() {
  const { data, startPolling, stopPolling } = useQuery(GET_VAULT_STATS, {
    pollInterval: 5000, // 5 seconds
  });

  useEffect(() => {
    startPolling(5000);
    return () => stopPolling();
  }, [startPolling, stopPolling]);

  return data?.vault;
}
```