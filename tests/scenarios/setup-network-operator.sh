#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/util.sh"

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

function deploy_root_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/base"
    wait_until_mofed_is_ready
}

function root_nic_policy() {
    deploy_root_nic_policy
    echo "TODO: Add tests that can be run using privileged user."
    echo "Not implemented yet"
    exit 1

}

function root_nic_policy_gpu() {
    deploy_root_nic_policy

    find_gpu_per_node
    kubectl apply -k "${SCRIPT_DIR}/k8s/root/gpu/${GPU_PER_NODE}"
    fail_on_job_failure "role=leader" "default"
    fail_on_job_failure "role=worker" "default"

    # Clean up
    kubectl delete -k "${SCRIPT_DIR}/k8s/root/gpu/${GPU_PER_NODE}"
}

function deploy_sriov_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/sriov"
    wait_until_mofed_is_ready
}

function sriov_nic_policy() {
    deploy_sriov_nic_policy
    echo "TODO: Add SRIOV tests"
    echo "Not implemented yet"
    exit 1
}

function sriov_nic_policy_gpu() {
    deploy_sriov_nic_policy
    echo "TODO: Add GPU based SRIOV tests"
    echo "Not implemented yet"
    exit 1
}

function deploy_ipoib_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/ipoib"
    wait_until_mofed_is_ready
}

function ipoib_nic_policy() {
    deploy_ipoib_nic_policy
    echo "TODO: Add IPOIB tests"
    echo "Not implemented yet"
    exit 1
}

function ipoib_nic_policy_gpu() {
    deploy_ipoib_nic_policy
    echo "TODO: Add GPU based IPOIB tests"
    echo "Not implemented yet"
    exit 1
}

function deploy_rdma_shared_device_plugin() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/rdma-shared-device-plugin"
    wait_until_mofed_is_ready

}

function rdma_shared_device_plugin() {
    deploy_rdma_shared_device_plugin
    echo "TODO: Add RDMA shared device plugin tests"
    echo "Not implemented yet"
    exit 1
}

function rdma_shared_device_plugin_gpu() {
    deploy_rdma_shared_device_plugin
    echo "TODO: Add GPU based RDMA shared device plugin tests"
    echo "Not implemented yet"
    exit 1
}

PARAM="${1:-}"
case $PARAM in
root-nic-policy)
    root_nic_policy
    ;;
root-nic-policy-gpu)
    root_nic_policy_gpu
    ;;
deploy-sriov-nic-policy)
    deploy_sriov_nic_policy
    ;;
deploy-sriov-nic-policy-gpu)
    deploy_sriov_nic_policy_gpu
    ;;
deploy-ipoib-nic-policy)
    deploy_ipoib_nic_policy
    ;;
deploy-ipoib-nic-policy-gpu)
    deploy_ipoib_nic_policy_gpu
    ;;
rdma-shared-device-plugin)
    deploy_rdma_shared_device_plugin
    ;;
rdma-shared-device-plugin-gpu)
    deploy_rdma_shared_device_plugin_gpu
    ;;
*)
    echo "Usage: $0 root-nic-policy | root-nic-policy-gpu | deploy-sriov-nic-policy | deploy-sriov-nic-policy-gpu | deploy-ipoib-nic-policy | deploy-ipoib-nic-policy-gpu | rdma-shared-device-plugin | rdma-shared-device-plugin-gpu"
    exit 1
    ;;
esac
