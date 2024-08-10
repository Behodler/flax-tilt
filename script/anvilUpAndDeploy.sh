#!/bin/bash
yarn anvil-down
# Determine the directory where the script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Change to the directory where the script is located.
cd "$SCRIPT_DIR"

# Now, any relative paths used in the script will be relative to the script's location.
echo "running shutdown..."
# Stop any existing Redis instances gracefully
redis-cli shutdown

echo "sleeping for 2 seconds to ensure proper shutdown"
sleep 2  

# Check if Redis has freed the default port
if ! lsof -i :6379; then
    echo "Redis port 6379 is free, proceeding with startup."
else
    echo "Redis port 6379 is still occupied. Check for lingering processes."
    exit 1
fi

echo "running startup..."
# Start a new ephemeral Redis instance if not running
if ! redis-cli ping; then
    echo "Redis is not running, starting new instance."
    redis-server --save "" --appendonly no --daemonize yes
else
    echo "Redis is already running."
fi

# Specify log file location
LOG_FILE="../anvil.log"

# Start anvil in the background and redirect all output to log file
anvil  --block-time 5 --port 8545 --accounts 10 > "$LOG_FILE" 2>&1 & 

# # Get the PID of the anvil process
ANVIL_PID=$!

# Store the PID in Redis
redis-cli SET anvil_pid $ANVIL_PID

echo "Anvil started with PID $ANVIL_PID and stored in Redis"

# Continue with the rest of the script
# Step 1: Delete addresses.json if it exists
touch ../addresses.json
rm -f ../addresses.json

echo "sleeping 2 for anvil"
sleep 2
# Step 2: Deploy contracts and update addresses.json
# forge script ./DeployContracts.s.sol --broadcast --rpc-url=http://localhost:8545 --json | jq -r '.[] | .name + ":" + .address' >> ../addresses.json
# forge script ./DeployContracts.s.sol --tc DeployContracts --broadcast --rpc-url=http://localhost:8545 --json
forge script ./DeployContracts.s.sol --tc DeployContracts --broadcast --rpc-url=http://localhost:8545 --json --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d | grep '^{.*}$' | jq 'del(.gas_used, .returns)' > ./output/addresses.json


ORACLE_ADDRESS=$(node set_uni_env.js)
export UNIORACLE=$ORACLE_ADDRESS
echo $ORACLE_ADDRESS

WETH_ADDRESS=$(node set_weth_env.js)
export WETH=$WETH_ADDRESS
echo $WETH_ADDRESS

FLAX_ADDRESS=$(node set_flax_env.js)
export FLAX=$FLAX_ADDRESS
echo $FLAX_ADDRESS

TILTER_ADDRESS=$(node set_tilter_env.js)
export TILTER=$TILTER_ADDRESS
echo $TILTER_ADDRESS

echo "sleeping for 31 seconds to allow oracle to update"
sleep 31

forge script ./UpdateOracles.s.sol --tc UpdateOracles --broadcast --rpc-url=http://localhost:8545 --json --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d 

# Step 3: Run a Node.js script to read addresses.json and update Redis
echo "executing node script"
node updateRedis.js
# sleep 5
node expressServer