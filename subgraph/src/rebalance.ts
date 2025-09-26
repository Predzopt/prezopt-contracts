import { BigInt } from "@graphprotocol/graph-ts"
import { Rebalanced as RebalancedEvent } from "../generated/RebalanceExecutor/RebalanceExecutor"
import { Rebalance } from "../generated/schema"

export function handleRebalanced(event: RebalancedEvent): void {
  // Create rebalance entity
  let rebalance = new Rebalance(event.transaction.hash.toHexString() + "-" + event.logIndex.toString())
  rebalance.fromStrategy = event.params.from
  rebalance.toStrategy = event.params.to
  rebalance.amount = event.params.amount
  rebalance.profit = event.params.profit
  rebalance.timestamp = event.block.timestamp
  rebalance.blockNumber = event.block.number
  rebalance.transactionHash = event.transaction.hash
  rebalance.save()
}