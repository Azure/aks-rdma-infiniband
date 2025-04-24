#!/usr/bin/env bash

set -euo pipefail

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
else
    echo "Debug mode is disabled. Set env var 'DEBUG=true' to enable debug mode."
fi

TESTS_DIR="/root/tests"

function sockperf() {
    # Can run on IB interface or regular NICs.
    bash ${TESTS_DIR}/sockperf-test.sh "${ROLE}"
}

function rdma_test() {
    # Needs IB devices, doesn't matter if there are GPUs or not.
    bash ${TESTS_DIR}/rdma_test.sh "${ROLE}" leader
}

function _check_if_lspci_available() {
    # Needs GPU
    which lspci >/dev/null 2>&1 || {
        echo "lspci command not found. Please run 'apt install -y pciutils'"
        exit 1
    }
}

function nccl_test_vllm_rdma() {
    _check_if_lspci_available

    # Check if the pod has NVIDIA GPUs
    if lspci | grep -i nvidia; then
        echo "NVIDIA GPUs found. Running GPU tests..."
        torchrun --nnodes 2 \
            --nproc-per-node=gpu \
            --rdzv_backend=static \
            --rdzv_endpoint=leader:29500 \
            --node_rank="${TORCH_RUN_RANK}" \
            ${TESTS_DIR}/vllm-rdma.py
    else
        echo "No NVIDIA GPUs found. Skipping GPU tests."
    fi
}

function nccl_test_gpudirect_rdma() {
    _check_if_lspci_available

    # Check if the pod has NVIDIA GPUs
    if lspci | grep -i nvidia; then
        echo "NVIDIA GPUs found. Running GPU tests..."
        torchrun --nnodes 2 \
            --nproc-per-node=gpu \
            --rdzv_backend=static \
            --rdzv_endpoint=leader:29500 \
            --node_rank="${TORCH_RUN_RANK}" \
            ${TESTS_DIR}/verify_gpudirect_rdma.py
    else
        echo "No NVIDIA GPUs found. Skipping GPU tests."
    fi
}

PARAM="${1:-all}"
case $PARAM in
sockperf)
    sockperf
    ;;
rdma_test | rdma-test)
    rdma_test
    ;;
nccl_test_vllm_rdma | nccl-test-vllm-rdma)
    nccl_test_vllm_rdma
    ;;
nccl_test_gpudirect_rdma | nccl-test-gpudirect-rdma)
    nccl_test_gpudirect_rdma
    ;;
debug)
    sleep inf
    ;;
all)
    sockperf
    rdma_test
    nccl_test_vllm_rdma
    nccl_test_gpudirect_rdma
    ;;
*)
    echo "Usage: $0 sockperf | rdma-test | nccl-test-vllm-rdma | nccl-test-gpudirect-rdma | debug | all"
    exit 1
    ;;
esac
