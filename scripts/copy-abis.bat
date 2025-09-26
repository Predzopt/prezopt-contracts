@echo off
echo Copying ABIs to subgraph...

copy out\PrezoptVault.sol\PrezoptVault.json subgraph\abis\
copy out\PZTStaking.sol\PZTStaking.json subgraph\abis\
copy out\RebalanceExecutor.sol\RebalanceExecutor.json subgraph\abis\

echo ABIs copied successfully!