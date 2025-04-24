#!/usr/bin/env bash

set -euo pipefail

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
else
    echo "Debug mode is disabled. Set env var 'DEBUG=true' to enable debug mode."
fi

EXIT_SERVER_PORT=11110
IPOIB_PORT=11111
ETH0_PORT=11112

function wait_until_endpoint_is_reachable() {
    local endpoint=$1
    local port=$2

    until nc -z "${endpoint}" "${port}"; do
        echo "Waiting for ${endpoint}:${port} server to be ready..."
        sleep 2
    done
    echo "Endpoint ${endpoint}:${port} is reachable."
}

function start_exit_server() {
    # Start a simple HTTP server to listen for exit requests
    echo "Starting exit server on port ${EXIT_SERVER_PORT}..."
    nc -l -p ${EXIT_SERVER_PORT} &
    EXIT_SERVER_PID=$!
    echo "Exit server started with PID ${EXIT_SERVER_PID}."
}

echo -e "\nStarting sockperf test...\n"

if [[ "$1" == "server" ]]; then
    # Start the exit server
    start_exit_server

    # Find if the pod has a network interface with the name net1 only then listen on the IPoIB interface.
    if ip addr show net1 2>/dev/null; then
        ipoib_ip=$(ip -j -4 addr show net1 | jq -r '.[0].addr_info[] | select(.family=="inet") | .local')
        echo -e "\nStarting sockperf test server on IPOIB interface...\n\n"
        sockperf server -i "${ipoib_ip}" --port ${IPOIB_PORT} --tcp --msg-size=1472 --daemonize &
    fi

    eth0_ip=$(ip -j -4 addr show eth0 | jq -r '.[0].addr_info[] | select(.family=="inet") | .local')
    echo -e "\nStarting sockperf test server on eth0 interface...\n\n"
    sockperf server -i "${eth0_ip}" --port ${ETH0_PORT} --tcp --msg-size=1472 --daemonize &

    # Wait for the exit server to terminate
    wait ${EXIT_SERVER_PID}

elif [[ "$1" == "client" ]]; then
    # Client Mode
    if ip addr show net1 2>/dev/null; then
        wait_until_endpoint_is_reachable leader-ib ${IPOIB_PORT}
        echo -e "\nRunning ping-pong test on IPOIB interface...\n\n"
        sockperf ping-pong -i leader-ib --port ${IPOIB_PORT} --tcp --msg-size=16384 -t 10 --pps=max
        echo -e "\nRunning throughput test on IPOIB interface...\n\n"
        sockperf throughput -i leader-ib --port ${IPOIB_PORT} --tcp --msg-size=1472
    fi

    wait_until_endpoint_is_reachable leader ${ETH0_PORT}
    echo -e "\nRunning ping-pong test on eth0 interface...\n\n"
    sockperf ping-pong -i leader --port ${ETH0_PORT} --tcp --msg-size=16384 -t 10 --pps=max

    wait_until_endpoint_is_reachable leader ${ETH0_PORT}
    echo -e "\nRunning throughput test on eth0 interface...\n\n"
    sockperf throughput -i leader --port ${ETH0_PORT} --tcp --msg-size=1472

    # Kill the server by sending request the the exit port.
    wait_until_endpoint_is_reachable leader ${EXIT_SERVER_PORT}
else
    echo "Usage: $0 server | client"
    exit 1
fi
