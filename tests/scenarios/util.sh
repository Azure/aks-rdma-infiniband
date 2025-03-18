#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

NETWORK_OPERATOR_NS="network-operator"
MOFED_LABEL="nvidia.com/ofed-driver"

function wait_until_mofed_is_ready() {
    # Wait until any MOFED pods show up.
    while true; do
        MOFED_PODS_COUNT="$(kubectl get pods \
            -n "${NETWORK_OPERATOR_NS}" \
            -l "${MOFED_LABEL}" \
            --no-headers | wc -l)"
        if [[ "${MOFED_PODS_COUNT}" -gt 0 ]]; then
            break
        fi

        echo "Waiting for mofed pods to show up..."
        sleep 2
    done

    echo "Waiting for all mofed pods in namespace '${NETWORK_OPERATOR_NS}' are ready (this may take 10 mins)..."
    while true; do
        MOFED_PODS_IN_READY_STATE="$(kubectl get pods \
            -n "${NETWORK_OPERATOR_NS}" \
            -l "${MOFED_LABEL}" \
            -o jsonpath='{range .items[*]}{.status.containerStatuses[*].ready}{" "}{end}' | tr ' ' '\n' | grep -c true || true)"
        MOFED_PODS_IN_READY_STATE="${MOFED_PODS_IN_READY_STATE:-0}"

        MOFED_PODS_COUNT_NEEDED="$(kubectl get pods \
            -n "${NETWORK_OPERATOR_NS}" \
            -l "${MOFED_LABEL}" \
            --no-headers | wc -l)"

        if [[ "${MOFED_PODS_IN_READY_STATE}" -eq "${MOFED_PODS_COUNT_NEEDED}" ]]; then
            sleep 15
            break
        fi

        echo "Not all mofed pods are ready yet... retrying in 5s (this may take 10 mins)"
        kubectl get pods -n "$NETWORK_OPERATOR_NS" -l "${MOFED_LABEL}" -o wide
        sleep 5
    done
}

function find_gpu_per_node() {
    case "${NODE_POOL_VM_SIZE}" in
    "Standard_ND96asr_v4" | "Standard_ND96amsr_A100_v4")
        GPU_PER_NODE=eight
        ;;
    *)
        echo "Unknown VM size: $NODE_POOL_VM_SIZE"
        exit 1
        ;;
    esac
}

function fail_on_job_failure() {
    # As soon as the job fails, print the logs and exit with an error.
    while true; do
        JOB_STATUS="$(kubectl get job -l "${1}" -n "${2}" -o jsonpath='{.items[*].status.conditions[?(@.type=="Failed")].status}')"
        if [[ "${JOB_STATUS}" == "True" ]]; then
            echo "Job '${1}' in namespace '${2}' failed. Printing logs..."
            kubectl logs -n "$2" "$(kubectl get pods -n "$2" -l "${1}" -o jsonpath='{.items[0].metadata.name}')" --all-containers
            exit 1
        fi

        JOB_STATUS="$(kubectl get job -l "${1}" -n "${2}" -o jsonpath='{.items[*].status.conditions[?(@.type=="Complete")].status}')"
        if [[ "${JOB_STATUS}" == "True" ]]; then
            break
        fi

        echo "Waiting for job '${1}' in namespace '${2}' to complete..."
        sleep 5
    done
}
