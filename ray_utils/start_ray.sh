#!/bin/bash

# Backward compatibility: if only RANK is provided, mirror it to RLINF_NODE_RANK.
if [ -n "$RANK" ] && [ -z "$RLINF_NODE_RANK" ]; then
    export RLINF_NODE_RANK="$RANK"
fi

# Parameter check
if [ -z "$RLINF_NODE_RANK" ]; then
    echo "Error: RLINF_NODE_RANK is not set!"
    echo "Set RLINF_NODE_RANK=<0..N-1> before starting Ray."
    exit 1
fi

NODE_RANK="$RLINF_NODE_RANK"

# Configuration file path (modify according to actual needs)
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_PATH=$(dirname "$SCRIPT_PATH")
RAY_HEAD_IP_FILE=$REPO_PATH/ray_utils/ray_head_ip.txt
RAY_PORT=${RAY_PORT:-29500}  # Default port for Ray, can be modified if needed

# Head node startup logic
if [ "$NODE_RANK" -eq 0 ]; then
    # Get local machine IP address (assumed to be intranet IP)
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    # Start Ray head node
    echo "Starting Ray head node on rank $NODE_RANK, IP: $IP_ADDRESS"
    ray start --head --memory=461708984320 --port=$RAY_PORT
    
    # Write IP to file
    echo "$IP_ADDRESS" > $RAY_HEAD_IP_FILE
    echo "Head node IP written to $RAY_HEAD_IP_FILE"
else
    # Worker node startup logic
    echo "Starting worker flow on rank $NODE_RANK. Waiting for head node IP file..."
    
    # Wait for file to appear (wait up to 360 seconds)
    for i in {1..360}; do
        if [ -f $RAY_HEAD_IP_FILE ]; then
            HEAD_ADDRESS=$(cat $RAY_HEAD_IP_FILE)
            if [ -n "$HEAD_ADDRESS" ]; then
                break
            fi
        fi
        sleep 1
    done
    
    if [ -z "$HEAD_ADDRESS" ]; then
        echo "Error: Could not get head node address from $RAY_HEAD_IP_FILE"
        exit 1
    fi
    
    echo "Starting Ray worker node connecting to head at $HEAD_ADDRESS"
    ray start --memory=461708984320 --address="$HEAD_ADDRESS:$RAY_PORT"
fi
