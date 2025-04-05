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
    fail_on_job_failure "app=nccl-tests" "default"

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
    fail_on_job_failure "app=nccl-tests" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/sriov/gpu/${GPU_PER_NODE}"
}

function deploy_ipoib_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/ipoib"
    wait_until_mofed_is_ready
    wait_until_ipoib_is_ready
}

function ipoib_nic_policy() {
    deploy_ipoib_nic_policy

    kubectl apply -k "${SCRIPT_DIR}/k8s/ipoib/base/"
    ipoib_add_ep_ip

    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/ipoib/base/"
}

function ipoib_nic_policy_gpu() {
    deploy_ipoib_nic_policy

    find_gpu_per_node
    kubectl apply -k "${SCRIPT_DIR}/k8s/ipoib/gpu/${GPU_PER_NODE}"
    ipoib_add_ep_ip

    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    echo "🧹 Cleaning up..."
    kubectl delete -k "${SCRIPT_DIR}/k8s/ipoib/gpu/${GPU_PER_NODE}"
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
root-nic-policy | root_nic_policy)
    root_nic_policy
    ;;
root-nic-policy-gpu | root_nic_policy_gpu)
    root_nic_policy_gpu
    ;;
sriov-nic-policy | sriov_nic_policy)
    sriov_nic_policy
    ;;
sriov-nic-policy-gpu | sriov_nic_policy_gpu)
    sriov_nic_policy_gpu
    ;;
ipoib-nic-policy | ipoib_nic_policy)
    ipoib_nic_policy
    ;;
ipoib-nic-policy-gpu | ipoib_nic_policy_gpu)
    ipoib_nic_policy_gpu
    ;;
rdma-shared-device-plugin | rdma_shared_device_plugin)
    rdma_shared_device_plugin
    ;;
rdma-shared-device-plugin-gpu | rdma_shared_device_plugin_gpu)
    rdma_shared_device_plugin_gpu
    ;;
*)
    echo "Usage: $0 root-nic-policy | root-nic-policy-gpu | sriov-nic-policy | sriov-nic-policy-gpu | ipoib-nic-policy | ipoib-nic-policy-gpu | rdma-shared-device-plugin | rdma-shared-device-plugin-gpu"
    exit 1
    ;;
esac
