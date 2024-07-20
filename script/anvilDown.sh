#!/bin/bash

# Check if Redis server is running
if ! redis-cli ping > /dev/null 2>&1; then
    echo "Redis server is not running."
    exit 1
fi

# Retrieve the PID from Redis
ANVIL_PID=$(redis-cli GET anvil_pid)

# Check if ANVIL_PID has a value
if [ -z "$ANVIL_PID" ]; then
    echo "No anvil PID found in Redis."
    exit 1
fi

# Attempt to kill the anvil process using the PID
kill -9 $ANVIL_PID > /dev/null 2>&1

# Check if the kill command was successful
if [ $? -eq 0 ]; then
    echo "Anvil process $ANVIL_PID has been stopped."
    # Clear the PID from Redis after stopping
    redis-cli DEL anvil_pid
else
    echo "Failed to stop Anvil process $ANVIL_PID. It may have already been terminated."
fi
