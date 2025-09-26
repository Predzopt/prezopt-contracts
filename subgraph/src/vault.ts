import { BigInt, BigDecimal } from "@graphprotocol/graph-ts"
import { Deposit as DepositEvent, Withdraw as WithdrawEvent } from "../generated/PrezoptVault/PrezoptVault"
import { Vault, User, Deposit, Withdrawal } from "../generated/schema"

export function handleDeposit(event: DepositEvent): void {
  let vault = getOrCreateVault()
  let user = getOrCreateUser(event.params.owner.toHexString())
  
  // Create deposit entity
  let deposit = new Deposit(event.transaction.hash.toHexString() + "-" + event.logIndex.toString())
  deposit.user = user.id
  deposit.assets = event.params.assets
  deposit.shares = event.params.shares
  deposit.timestamp = event.block.timestamp
  deposit.blockNumber = event.block.number
  deposit.transactionHash = event.transaction.hash
  deposit.save()
  
  // Update user
  user.vaultShares = user.vaultShares.plus(event.params.shares)
  user.vaultAssets = user.vaultAssets.plus(event.params.assets)
  user.depositCount = user.depositCount.plus(BigInt.fromI32(1))
  user.totalDeposited = user.totalDeposited.plus(event.params.assets)
  user.updatedAt = event.block.timestamp
  user.save()
  
  // Update vault
  vault.totalSupply = vault.totalSupply.plus(event.params.shares)
  vault.totalAssets = vault.totalAssets.plus(event.params.assets)
  vault.depositCount = vault.depositCount.plus(BigInt.fromI32(1))
  vault.updatedAt = event.block.timestamp
  updateSharePrice(vault)
  vault.save()
}

export function handleWithdraw(event: WithdrawEvent): void {
  let vault = getOrCreateVault()
  let user = getOrCreateUser(event.params.owner.toHexString())
  
  // Create withdrawal entity
  let withdrawal = new Withdrawal(event.transaction.hash.toHexString() + "-" + event.logIndex.toString())
  withdrawal.user = user.id
  withdrawal.assets = event.params.assets
  withdrawal.shares = event.params.shares
  withdrawal.timestamp = event.block.timestamp
  withdrawal.blockNumber = event.block.number
  withdrawal.transactionHash = event.transaction.hash
  withdrawal.save()
  
  // Update user
  user.vaultShares = user.vaultShares.minus(event.params.shares)
  user.vaultAssets = user.vaultAssets.minus(event.params.assets)
  user.withdrawalCount = user.withdrawalCount.plus(BigInt.fromI32(1))
  user.totalWithdrawn = user.totalWithdrawn.plus(event.params.assets)
  user.updatedAt = event.block.timestamp
  user.save()
  
  // Update vault
  vault.totalSupply = vault.totalSupply.minus(event.params.shares)
  vault.totalAssets = vault.totalAssets.minus(event.params.assets)
  vault.withdrawalCount = vault.withdrawalCount.plus(BigInt.fromI32(1))
  vault.updatedAt = event.block.timestamp
  updateSharePrice(vault)
  vault.save()
}

function getOrCreateVault(): Vault {
  let vault = Vault.load("vault")
  if (vault == null) {
    vault = new Vault("vault")
    vault.totalAssets = BigInt.fromI32(0)
    vault.totalSupply = BigInt.fromI32(0)
    vault.sharePrice = BigDecimal.fromString("1")
    vault.depositCount = BigInt.fromI32(0)
    vault.withdrawalCount = BigInt.fromI32(0)
    vault.createdAt = BigInt.fromI32(0)
    vault.updatedAt = BigInt.fromI32(0)
  }
  return vault
}

function getOrCreateUser(address: string): User {
  let user = User.load(address)
  if (user == null) {
    user = new User(address)
    user.vaultShares = BigInt.fromI32(0)
    user.vaultAssets = BigInt.fromI32(0)
    user.stakedPZT = BigInt.fromI32(0)
    user.pendingRewards = BigInt.fromI32(0)
    user.depositCount = BigInt.fromI32(0)
    user.withdrawalCount = BigInt.fromI32(0)
    user.totalDeposited = BigInt.fromI32(0)
    user.totalWithdrawn = BigInt.fromI32(0)
    user.createdAt = BigInt.fromI32(0)
    user.updatedAt = BigInt.fromI32(0)
  }
  return user
}

function updateSharePrice(vault: Vault): void {
  if (vault.totalSupply.gt(BigInt.fromI32(0))) {
    vault.sharePrice = vault.totalAssets.toBigDecimal().div(vault.totalSupply.toBigDecimal())
  } else {
    vault.sharePrice = BigDecimal.fromString("1")
  }
}