#!/usr/bin/env bash

set -euo pipefail

set -x

export TESTS_DIR="/root/tests"

bash ${TESTS_DIR}/rdma_test.sh ${ROLE} leader

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
