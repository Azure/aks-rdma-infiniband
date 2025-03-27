#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/util.sh"

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

function deploy_root_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/base"
    wait_until_mofed_is_ready
}

function root_nic_policy() {
    deploy_root_nic_policy

    kubectl apply -k "${SCRIPT_DIR}/k8s/root/base"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    # Clean up
    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/root/base"
}

function root_nic_policy_gpu() {
    deploy_root_nic_policy

    find_gpu_per_node
    kubectl apply -k "${SCRIPT_DIR}/k8s/root/gpu/${GPU_PER_NODE}"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    # Clean up
    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/root/gpu/${GPU_PER_NODE}"
}

function deploy_sriov_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/sriov-device-plugin"
    wait_until_mofed_is_ready
    wait_until_sriov_is_ready
}

function sriov_nic_policy() {
    deploy_sriov_nic_policy

    kubectl apply -k "${SCRIPT_DIR}/k8s/sriov/base"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    # Clean up
    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/sriov/base"
}

function sriov_nic_policy_gpu() {
    deploy_sriov_nic_policy

    find_gpu_per_node
    kubectl apply -k "${SCRIPT_DIR}/k8s/sriov/gpu/${GPU_PER_NODE}"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/sriov/gpu/${GPU_PER_NODE}"
}

function deploy_ipoib_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/ipoib"
    wait_until_mofed_is_ready
}

function ipoib_nic_policy() {
    deploy_ipoib_nic_policy
    echo "📝 TODO: Add IPOIB tests"
    echo "❌ Not implemented yet"
    exit 1
}

function ipoib_nic_policy_gpu() {
    deploy_ipoib_nic_policy
    echo "📝 TODO: Add GPU based IPOIB tests"
    echo "❌ Not implemented yet"
    exit 1
}

function deploy_rdma_shared_device_plugin() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/rdma-shared-device-plugin"
    wait_until_mofed_is_ready
    wait_until_rdma_is_ready
}

function rdma_shared_device_plugin() {
    deploy_rdma_shared_device_plugin

    kubectl apply -k "${SCRIPT_DIR}/k8s/rdma/base"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/rdma/base"
}

function rdma_shared_device_plugin_gpu() {
    deploy_rdma_shared_device_plugin

    find_gpu_per_node
    kubectl apply -k "${SCRIPT_DIR}/k8s/rdma/gpu/${GPU_PER_NODE}"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/rdma/gpu/${GPU_PER_NODE}"
}

PARAM="${1:-}"
case $PARAM in
root-nic-policy)
    root_nic_policy
    ;;
root-nic-policy-gpu)
    root_nic_policy_gpu
    ;;
sriov-nic-policy)
    sriov_nic_policy
    ;;
sriov-nic-policy-gpu)
    sriov_nic_policy_gpu
    ;;
deploy-ipoib-nic-policy)
    deploy_ipoib_nic_policy
    ;;
deploy-ipoib-nic-policy-gpu)
    deploy_ipoib_nic_policy_gpu
    ;;
rdma-shared-device-plugin)
    rdma_shared_device_plugin
    ;;
rdma-shared-device-plugin-gpu)
    rdma_shared_device_plugin_gpu
    ;;
*)
    echo "Usage: $0 root-nic-policy | root-nic-policy-gpu | sriov-nic-policy | sriov-nic-policy-gpu | deploy-ipoib-nic-policy | deploy-ipoib-nic-policy-gpu | rdma-shared-device-plugin | rdma-shared-device-plugin-gpu"
    exit 1
    ;;
esac
