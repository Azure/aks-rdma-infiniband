#!/usr/bin/env bash

# RDMA Over InfiniBand Test Script
# Usage:
#   - Server: ./rdma_test.sh server
#   - Client: ./rdma_test.sh client leader

set -euo pipefail

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
else
    echo "Debug mode is disabled. Set env var 'DEBUG=true' to enable debug mode."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Set the RDMA port
export PORT=18515

function get_ib_devices() {
    # Get the list of available IB devices
    IB_DEVICES=$(ibstat -s | grep "CA '" | cut -d"'" -f2) || true

    # Check if IB devices exist
    if [[ -z "$IB_DEVICES" ]]; then
        echo "No InfiniBand devices found!"
        exit 1
    fi

    echo "Detected IB Devices:"
    echo "$IB_DEVICES"
}

function check_tools() {
    # Function to check if a command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    # Check for required RDMA tools
    for cmd in ibstat ibv_rc_pingpong ib_read_lat ib_read_bw; do
        if ! command_exists "$cmd"; then
            echo "Error: $cmd not found. Run: apt install -y infiniband-diags ibverbs-utils perftest"
            exit 1
        fi
    done
}

function check_ib_device_is_active() {
    # Check if the IB device is active
    IB_DEVICE_STATE=$(ibstat "$IB_DEVICE" | grep State | cut -d':' -f2 | tr -d '[:space:]')
    if [[ "${IB_DEVICE_STATE}" != "Active" ]]; then
        echo "Error: ${IB_DEVICE} is not active!"
        exit 1
    fi
}

get_ib_devices
check_tools

# Server Mode
if [[ "$1" == "server" ]]; then
    echo "Starting RDMA Server..."
    for IB_DEVICE in $IB_DEVICES; do
        echo "Testing RDMA on device: $IB_DEVICE (Port $PORT)"

        check_ib_device_is_active

        # Run RDMA ping-pong test
        ibv_rc_pingpong --ib-dev "$IB_DEVICE"

        # Run RDMA latency test
        ib_read_lat --ib-dev "$IB_DEVICE"

        # Run RDMA bandwidth test
        ib_read_bw --ib-dev "$IB_DEVICE"

    done

# Client Mode
elif [[ "$1" == "client" && -n "$2" ]]; then
    SERVER_IP="$2"

    echo "Starting RDMA Client, connecting to $SERVER_IP..."
    for IB_DEVICE in $IB_DEVICES; do
        echo "Testing RDMA on device: $IB_DEVICE (Port $PORT)"

        check_ib_device_is_active

        # Run RDMA ping-pong test
        # Try this command until the server is ready
        until ibv_rc_pingpong --ib-dev "$IB_DEVICE" -p $PORT "$SERVER_IP"; do
            echo "Waiting for 'ibv_rc_pingpong' server to be ready for $IB_DEVICE..."
            sleep 2
        done

        # Run RDMA latency test
        until ib_read_lat --ib-dev "$IB_DEVICE" -p $PORT "$SERVER_IP"; do
            echo "Waiting for 'ib_read_lat' server to be ready for $IB_DEVICE..."
            sleep 2
        done

        # Run RDMA bandwidth test
        until ib_read_bw --ib-dev "$IB_DEVICE" -p $PORT "$SERVER_IP"; do
            echo "Waiting for 'ib_read_bw' server to be ready for $IB_DEVICE..."
            sleep 2
        done

    done

else
    echo "Usage: $0 server | client <server_ib_ip>"
    exit 1
fi
