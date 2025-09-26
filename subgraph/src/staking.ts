import { BigInt } from "@graphprotocol/graph-ts"
import { 
  Staked as StakedEvent, 
  Unstaked as UnstakedEvent,
  RewardsClaimed as RewardsClaimedEvent 
} from "../generated/PZTStaking/PZTStaking"
import { StakingUser, StakeEvent } from "../generated/schema"

export function handleStaked(event: StakedEvent): void {
  let user = getOrCreateStakingUser(event.params.user.toHexString())
  
  // Create stake event
  let stakeEvent = new StakeEvent(event.transaction.hash.toHexString() + "-" + event.logIndex.toString())
  stakeEvent.user = user.id
  stakeEvent.amount = event.params.amount
  stakeEvent.type = "STAKE"
  stakeEvent.timestamp = event.block.timestamp
  stakeEvent.blockNumber = event.block.number
  stakeEvent.transactionHash = event.transaction.hash
  stakeEvent.save()
  
  // Update user
  user.stakedAmount = user.stakedAmount.plus(event.params.amount)
  user.stakeCount = user.stakeCount.plus(BigInt.fromI32(1))
  user.updatedAt = event.block.timestamp
  user.save()
}

export function handleUnstaked(event: UnstakedEvent): void {
  let user = getOrCreateStakingUser(event.params.user.toHexString())
  
  // Create unstake event
  let stakeEvent = new StakeEvent(event.transaction.hash.toHexString() + "-" + event.logIndex.toString())
  stakeEvent.user = user.id
  stakeEvent.amount = event.params.amount
  stakeEvent.type = "UNSTAKE"
  stakeEvent.timestamp = event.block.timestamp
  stakeEvent.blockNumber = event.block.number
  stakeEvent.transactionHash = event.transaction.hash
  stakeEvent.save()
  
  // Update user
  user.stakedAmount = user.stakedAmount.minus(event.params.amount)
  user.unstakeCount = user.unstakeCount.plus(BigInt.fromI32(1))
  user.updatedAt = event.block.timestamp
  user.save()
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
  let user = getOrCreateStakingUser(event.params.user.toHexString())
  
  // Update user rewards
  user.rewardsClaimed = user.rewardsClaimed.plus(event.params.amount)
  user.updatedAt = event.block.timestamp
  user.save()
}

function getOrCreateStakingUser(address: string): StakingUser {
  let user = StakingUser.load(address)
  if (user == null) {
    user = new StakingUser(address)
    user.stakedAmount = BigInt.fromI32(0)
    user.rewardsClaimed = BigInt.fromI32(0)
    user.stakeCount = BigInt.fromI32(0)
    user.unstakeCount = BigInt.fromI32(0)
    user.createdAt = BigInt.fromI32(0)
    user.updatedAt = BigInt.fromI32(0)
  }
  return user
}