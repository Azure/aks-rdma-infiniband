#!/usr/bin/env bash

set -euo pipefail

set -x

export TESTS_DIR="/root/tests"

# Does not need GPU.
# Needs IB.
bash ${TESTS_DIR}/rdma_test.sh ${ROLE} leader

# Needs GPU
which lspci >/dev/null 2>&1 || {
    echo "lspci command not found. Please run 'apt install -y pciutils'"
    exit 1
}

# Check if the pod has NVIDIA GPUs
if lspci | grep -i nvidia; then
    torchrun --nnodes 2 \
        --nproc-per-node=gpu \
        --rdzv_backend=static \
        --rdzv_endpoint=leader:29500 \
        --node_rank=${TORCH_RUN_RANK} \
        ${TESTS_DIR}/vllm-rdma.py

    torchrun --nnodes 2 \
        --nproc-per-node=gpu \
        --rdzv_backend=static \
        --rdzv_endpoint=leader:29500 \
        --node_rank=${TORCH_RUN_RANK} \
        ${TESTS_DIR}/verify_gpudirect_rdma.py
else
    echo "No NVIDIA GPUs found. Skipping GPU tests."
    exit 0
fi
