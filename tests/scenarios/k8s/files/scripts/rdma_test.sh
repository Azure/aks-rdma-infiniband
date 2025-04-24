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

# Set the RDMA port
export PORT=18515

function check_ib_devices() {
    # If the output of the command `ibv_devinfo` is `No IB devices found` then
    # there aren't IB devices to run the rdma_test.sh.
    output=$(ibv_devinfo 2>&1 || true)
    if echo "$output" | grep -q "No IB devices found"; then
        echo "No IB devices found. Skipping RDMA tests."
        exit 0
    fi
}

function get_ib_devices() {
    # Get the list of available IB devices. There is a possibility that the node
    # has a NIC that shows up as mlx but is not an IB device. It could be using
    # Ethernet at the link layer. So ignore such devices.
    #
    # One way to ignore such devices at NCCL level is to set "export
    # NCCL_IB_HCA=^mlx5_8". So here we are ignoring the mlx5_8 device.
    # See the failures like this: https://gist.github.com/surajssd/d65a9eb3844bfc49ccda3e84a0ff5a4b#file-nccl-failure-on-roce-mlx5_8-device-sh
    IB_DEVICE_INFO=$(ibv_devinfo -l | grep -v 'HCA' | tr -d ' ')
    IB_DEVICES=$(for dev in $IB_DEVICE_INFO; do
        # Check if the device is an InfiniBand device
        if [[ $(ibv_devinfo -d "$dev" | grep link_layer | grep -c "InfiniBand") -gt 0 ]]; then
            echo "$dev"
        fi
    done)

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

check_ib_devices
get_ib_devices
check_tools

# Server Mode
if [[ "$1" == "server" ]]; then
    for IB_DEVICE in $IB_DEVICES; do
        echo -e "\nTesting RDMA on device: $IB_DEVICE (Port $PORT)\n"

        check_ib_device_is_active

        echo -e "\nStarting RDMA Server 'ibv_rc_pingpong' for $IB_DEVICE (Port $PORT)...\n"
        # Run RDMA ping-pong test
        ibv_rc_pingpong --ib-dev "$IB_DEVICE"

        echo -e "\nStarting RDMA Server 'ib_read_lat' for $IB_DEVICE (Port $PORT)...\n"
        # Run RDMA latency test
        ib_read_lat --ib-dev "$IB_DEVICE"

        echo -e "\nStarting RDMA Server 'ib_read_bw' for $IB_DEVICE (Port $PORT)...\n"
        # Run RDMA bandwidth test
        ib_read_bw --ib-dev "$IB_DEVICE" -a -F --report_gbits -q 1

        echo -e "\nStarting RDMA Server 'ib_write_bw' for $IB_DEVICE (Port $PORT)...\n"
        # Run RDMA write bandwidth test
        ib_write_bw --ib-dev "$IB_DEVICE" -a -F --report_gbits -q 1
    done

# Client Mode
elif [[ "$1" == "client" && -n "$2" ]]; then
    SERVER_IP="$2"

    echo "Starting RDMA Client, connecting to $SERVER_IP..."
    for IB_DEVICE in $IB_DEVICES; do
        echo -e "\nTesting RDMA on device: $IB_DEVICE (Port $PORT)\n"

        check_ib_device_is_active

        # Run RDMA ping-pong test
        echo -e "\nStarting RDMA client 'ibv_rc_pingpong' for $IB_DEVICE (Port $PORT)...\n"
        # Try this command until the server is ready
        until ibv_rc_pingpong --ib-dev "$IB_DEVICE" -p $PORT "$SERVER_IP"; do
            echo "Waiting for 'ibv_rc_pingpong' server to be ready for $IB_DEVICE..."
            sleep 2
        done

        # Run RDMA latency test
        echo -e "\nStarting RDMA client 'ib_read_lat' for $IB_DEVICE (Port $PORT)...\n"
        until ib_read_lat --ib-dev "$IB_DEVICE" -p $PORT "$SERVER_IP"; do
            echo "Waiting for 'ib_read_lat' server to be ready for $IB_DEVICE..."
            sleep 2
        done

        # Run RDMA bandwidth test
        echo -e "\nStarting RDMA client 'ib_read_bw' for $IB_DEVICE (Port $PORT)...\n"
        until ib_read_bw --ib-dev "$IB_DEVICE" -p $PORT -n 5000 -a -F --report_gbits -q 1 "$SERVER_IP"; do
            echo "Waiting for 'ib_read_bw' server to be ready for $IB_DEVICE..."
            sleep 2
        done

        # Run RDMA write bandwidth test
        echo -e "\nStarting RDMA client 'ib_write_bw' for $IB_DEVICE (Port $PORT)...\n"
        until ib_write_bw --ib-dev "$IB_DEVICE" -p $PORT -n 5000 -a -F --report_gbits -q 1 "$SERVER_IP"; do
            echo "Waiting for 'ib_write_bw' server to be ready for $IB_DEVICE..."
            sleep 2
        done
    done

else
    echo "Usage: $0 server | client <server_ib_ip>"
    exit 1
fi
