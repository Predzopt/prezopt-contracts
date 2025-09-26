# Frontend Integration Guide

## Contract ABIs

Export ABIs after deployment:
```bash
forge build
cp out/PrezoptVault.sol/PrezoptVault.json frontend/src/abis/
cp out/PZTToken.sol/PZTToken.json frontend/src/abis/
cp out/PZTStaking.sol/PZTStaking.json frontend/src/abis/
cp out/MockUSDC.sol/MockUSDC.json frontend/src/abis/
cp out/MockAaveStrategy.sol/MockAaveStrategy.json frontend/src/abis/
```

## Contract Addresses

```typescript
// contracts.ts
export const CONTRACTS = {
  VAULT: "0x...", // PrezoptVault
  PZT_TOKEN: "0x...", // PZTToken
  PZT_STAKING: "0x...", // PZTStaking
  MOCK_USDC: "0x...", // MockUSDC
  MOCK_AAVE_STRATEGY: "0x...", // MockAaveStrategy
  MOCK_COMPOUND_STRATEGY: "0x...", // MockCompoundStrategy
  MOCK_CURVE_STRATEGY: "0x...", // MockCurveStrategy
  MOCK_YEARN_STRATEGY: "0x...", // MockYearnStrategy
};
```

## Ethers.js Integration

### Setup
```typescript
import { ethers } from 'ethers';
import { CONTRACTS } from './contracts';
import VaultABI from './abis/PrezoptVault.json';
import TokenABI from './abis/PZTToken.json';
import StakingABI from './abis/PZTStaking.json';
import MockUSDCABI from './abis/MockUSDC.json';

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

const vault = new ethers.Contract(CONTRACTS.VAULT, VaultABI.abi, signer);
const pztToken = new ethers.Contract(CONTRACTS.PZT_TOKEN, TokenABI.abi, signer);
const staking = new ethers.Contract(CONTRACTS.PZT_STAKING, StakingABI.abi, signer);
const usdc = new ethers.Contract(CONTRACTS.MOCK_USDC, MockUSDCABI.abi, signer);
```

### Vault Operations
```typescript
// Deposit USDC
async function deposit(amount: string) {
  const amountWei = ethers.utils.parseUnits(amount, 6); // USDC has 6 decimals
  
  // Approve USDC
  await usdc.approve(CONTRACTS.VAULT, amountWei);
  
  // Deposit to vault
  const tx = await vault.deposit(amountWei, await signer.getAddress());
  return await tx.wait();
}

// Withdraw from vault
async function withdraw(shares: string) {
  const sharesWei = ethers.utils.parseEther(shares);
  const tx = await vault.redeem(sharesWei, await signer.getAddress(), await signer.getAddress());
  return await tx.wait();
}

// Get user balance
async function getVaultBalance() {
  const address = await signer.getAddress();
  const shares = await vault.balanceOf(address);
  const assets = await vault.convertToAssets(shares);
  return {
    shares: ethers.utils.formatEther(shares),
    assets: ethers.utils.formatUnits(assets, 6)
  };
}

// Get vault stats
async function getVaultStats() {
  const totalAssets = await vault.totalAssets();
  const totalSupply = await vault.totalSupply();
  return {
    totalAssets: ethers.utils.formatUnits(totalAssets, 6),
    totalSupply: ethers.utils.formatEther(totalSupply),
    sharePrice: totalSupply.gt(0) ? totalAssets.mul(ethers.utils.parseEther("1")).div(totalSupply) : ethers.utils.parseEther("1")
  };
}
```

### PZT Staking
```typescript
// Stake PZT tokens
async function stakePZT(amount: string) {
  const amountWei = ethers.utils.parseEther(amount);
  
  // Approve PZT
  await pztToken.approve(CONTRACTS.PZT_STAKING, amountWei);
  
  // Stake
  const tx = await staking.stake(amountWei);
  return await tx.wait();
}

// Unstake PZT tokens
async function unstakePZT(amount: string) {
  const amountWei = ethers.utils.parseEther(amount);
  const tx = await staking.unstake(amountWei);
  return await tx.wait();
}

// Claim rewards
async function claimRewards() {
  const tx = await staking.claimRewards();
  return await tx.wait();
}

// Get staking info
async function getStakingInfo() {
  const address = await signer.getAddress();
  const stakedAmount = await staking.stakedBalance(address);
  const pendingRewards = await staking.pendingRewards(address);
  const totalStaked = await staking.totalStaked();
  
  return {
    stakedAmount: ethers.utils.formatEther(stakedAmount),
    pendingRewards: ethers.utils.formatUnits(pendingRewards, 6),
    totalStaked: ethers.utils.formatEther(totalStaked)
  };
}
```

### Strategy Information
```typescript
// Get strategy APYs
async function getStrategyAPYs() {
  const aaveStrategy = new ethers.Contract(CONTRACTS.MOCK_AAVE_STRATEGY, MockStrategyABI.abi, provider);
  const compoundStrategy = new ethers.Contract(CONTRACTS.MOCK_COMPOUND_STRATEGY, MockStrategyABI.abi, provider);
  const curveStrategy = new ethers.Contract(CONTRACTS.MOCK_CURVE_STRATEGY, MockStrategyABI.abi, provider);
  const yearnStrategy = new ethers.Contract(CONTRACTS.MOCK_YEARN_STRATEGY, MockStrategyABI.abi, provider);
  
  const [aaveAPY, compoundAPY, curveAPY, yearnAPY] = await Promise.all([
    aaveStrategy.getCurrentAPY(),
    compoundStrategy.getCurrentAPY(),
    curveStrategy.getCurrentAPY(),
    yearnStrategy.getCurrentAPY()
  ]);
  
  return {
    aave: (aaveAPY.toNumber() / 100).toFixed(2) + '%',
    compound: (compoundAPY.toNumber() / 100).toFixed(2) + '%',
    curve: (curveAPY.toNumber() / 100).toFixed(2) + '%',
    yearn: (yearnAPY.toNumber() / 100).toFixed(2) + '%'
  };
}

// Get strategy allocations
async function getStrategyAllocations() {
  const [aaveAssets, compoundAssets, curveAssets, yearnAssets] = await Promise.all([
    aaveStrategy.estimatedTotalAssets(),
    compoundStrategy.estimatedTotalAssets(),
    curveStrategy.estimatedTotalAssets(),
    yearnStrategy.estimatedTotalAssets()
  ]);
  
  const total = aaveAssets.add(compoundAssets).add(curveAssets).add(yearnAssets);
  
  return {
    aave: total.gt(0) ? aaveAssets.mul(100).div(total).toNumber() : 0,
    compound: total.gt(0) ? compoundAssets.mul(100).div(total).toNumber() : 0,
    curve: total.gt(0) ? curveAssets.mul(100).div(total).toNumber() : 0,
    yearn: total.gt(0) ? yearnAssets.mul(100).div(total).toNumber() : 0
  };
}
```

### Event Listeners
```typescript
// Listen to vault events
vault.on("Deposit", (sender, owner, assets, shares) => {
  console.log("Deposit:", {
    sender,
    owner,
    assets: ethers.utils.formatUnits(assets, 6),
    shares: ethers.utils.formatEther(shares)
  });
});

vault.on("Withdraw", (sender, receiver, owner, assets, shares) => {
  console.log("Withdraw:", {
    sender,
    receiver,
    owner,
    assets: ethers.utils.formatUnits(assets, 6),
    shares: ethers.utils.formatEther(shares)
  });
});

// Listen to staking events
staking.on("Staked", (user, amount) => {
  console.log("Staked:", {
    user,
    amount: ethers.utils.formatEther(amount)
  });
});
```

### Error Handling
```typescript
async function safeContractCall(contractCall: () => Promise<any>) {
  try {
    return await contractCall();
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error("Transaction rejected by user");
    } else if (error.code === -32603) {
      throw new Error("Internal JSON-RPC error");
    } else {
      throw new Error(error.reason || error.message || "Transaction failed");
    }
  }
}
```

## React Hook Example
```typescript
import { useState, useEffect } from 'react';

export function useVaultData() {
  const [vaultStats, setVaultStats] = useState(null);
  const [userBalance, setUserBalance] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchData() {
      try {
        const [stats, balance] = await Promise.all([
          getVaultStats(),
          getVaultBalance()
        ]);
        setVaultStats(stats);
        setUserBalance(balance);
      } catch (error) {
        console.error("Failed to fetch vault data:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
    const interval = setInterval(fetchData, 30000); // Update every 30s
    return () => clearInterval(interval);
  }, []);

  return { vaultStats, userBalance, loading };
}
```