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

echo "sleeping for 5 seconds to ensure proper shutdown"
sleep 5  

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
anvil  --block-time 2 --port 8545 --accounts 10 > "$LOG_FILE" 2>&1 & 

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

# Step 3: Run a Node.js script to read addresses.json and update Redis

# node updateRedis.js
# node expressServer