#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/util.sh"

export HELM_INSTALL_CMD="helm upgrade -i --wait test ${SCRIPT_DIR}/k8s --values ${SCRIPT_DIR}/k8s/values.yaml"
export HELM_UNINSTALL_CMD="helm uninstall test --wait"
export TEST_DEBUG_FLAGS=()

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
    export TEST_DEBUG_FLAGS=(
        --debug
        --values "${SCRIPT_DIR}"/k8s/values-debug.yaml
    )
fi

function deploy_root_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/base"
    wait_until_mofed_is_ready
}

function root_nic_policy() {
    deploy_root_nic_policy

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            --set securityContext.privileged=true \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        echo "❌ Can't run mpijob without GPUs"
        exit 1
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function root_nic_policy_gpu() {
    deploy_root_nic_policy

    find_gpu_per_node
    mpi_job_number_of_processes

    local test_flags=(
        --set "securityContext.privileged=true"
        --set "resources.nvidia\.com/gpu=${GPU_PER_NODE_NUMBER}"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set mpiJob.enabled=true \
            --set mpiJob.numberOfProcesses="${NUMBER_OF_PROCESSES}"

        fail_on_job_failure "app=nccl-tests" "default"
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function deploy_sriov_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/sriov-device-plugin"
    wait_until_mofed_is_ready
    wait_until_sriov_is_ready
}

function sriov_nic_policy() {
    deploy_sriov_nic_policy

    local test_flags=(
        --set "securityContext.capabilities.add={IPC_LOCK}"
        --set "resources.rdma/ib=1"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        echo "❌ Can't run mpijob without GPUs"
        exit 1
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function sriov_nic_policy_gpu() {
    deploy_sriov_nic_policy

    find_gpu_per_node
    mpi_job_number_of_processes

    local test_flags=(
        --set "securityContext.capabilities.add={IPC_LOCK}"
        --set "resources.nvidia\.com/gpu=${GPU_PER_NODE_NUMBER}"
        --set "resources.rdma/ib=${GPU_PER_NODE_NUMBER}"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set mpiJob.enabled=true \
            --set mpiJob.numberOfProcesses="${NUMBER_OF_PROCESSES}"

        fail_on_job_failure "app=nccl-tests" "default"
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function deploy_ipoib_nic_policy() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/ipoib"
    wait_until_mofed_is_ready
    wait_until_ipoib_is_ready
}

function ipoib_nic_policy() {
    deploy_ipoib_nic_policy

    local test_flags=(
        --set "ipoib=true"
        --set "ncclEnvVars.NCCL_SOCKET_IFNAME=net1"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"
        ipoib_add_ep_ip

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        echo "❌ Can't run mpijob without GPUs"
        exit 1
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function ipoib_nic_policy_gpu() {
    deploy_ipoib_nic_policy

    find_gpu_per_node
    mpi_job_number_of_processes

    local test_flags=(
        --set "resources.nvidia\.com/gpu=${GPU_PER_NODE_NUMBER}"
        --set "ipoib=true"
        --set "ncclEnvVars.NCCL_SOCKET_IFNAME=net1"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"
        ipoib_add_ep_ip

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set mpiJob.enabled=true \
            --set mpiJob.numberOfProcesses="${NUMBER_OF_PROCESSES}"

        fail_on_job_failure "app=nccl-tests" "default"
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function deploy_rdma_shared_device_plugin() {
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/rdma-shared-device-plugin"
    wait_until_mofed_is_ready
    wait_until_rdma_is_ready
}

function rdma_shared_device_plugin() {
    deploy_rdma_shared_device_plugin

    local test_flags=(
        --set "securityContext.capabilities.add={IPC_LOCK}"
        --set "resources.rdma/shared_ib=1"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        echo "❌ Can't run mpijob without GPUs"
        exit 1
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

function rdma_shared_device_plugin_gpu() {
    deploy_rdma_shared_device_plugin

    find_gpu_per_node
    mpi_job_number_of_processes

    local test_flags=(
        --set "securityContext.capabilities.add={IPC_LOCK}"
        --set "resources.nvidia\.com/gpu=${GPU_PER_NODE_NUMBER}"
        --set "resources.rdma/shared_ib=1"
    )

    if [[ ${subcmd} != "mpijob" ]]; then
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set job.enabled=true \
            --set job.testFunctionName="${subcmd}"

        fail_on_job_failure "role=leader" "default"
        fail_on_job_failure "role=worker" "default"
    else
        $HELM_INSTALL_CMD "${TEST_DEBUG_FLAGS[@]}" \
            "${test_flags[@]}" \
            --set mpiJob.enabled=true \
            --set mpiJob.numberOfProcesses="${NUMBER_OF_PROCESSES}"

        fail_on_job_failure "app=nccl-tests" "default"
    fi

    echo "🧹 Cleaning up..."
    $HELM_UNINSTALL_CMD
}

cmd="${1:-}"
case $cmd in
root-nic-policy | root_nic_policy)
    DEPLOY_METHOD_FUNC="root_nic_policy"
    ;;
root-nic-policy-gpu | root_nic_policy_gpu)
    DEPLOY_METHOD_FUNC="root_nic_policy_gpu"
    ;;
sriov-nic-policy | sriov_nic_policy)
    DEPLOY_METHOD_FUNC="sriov_nic_policy"
    ;;
sriov-nic-policy-gpu | sriov_nic_policy_gpu)
    DEPLOY_METHOD_FUNC="sriov_nic_policy_gpu"
    ;;
ipoib-nic-policy | ipoib_nic_policy)
    DEPLOY_METHOD_FUNC="ipoib_nic_policy"
    ;;
ipoib-nic-policy-gpu | ipoib_nic_policy_gpu)
    DEPLOY_METHOD_FUNC="ipoib_nic_policy_gpu"
    ;;
rdma-shared-device-plugin | rdma_shared_device_plugin)
    DEPLOY_METHOD_FUNC="rdma_shared_device_plugin"
    ;;
rdma-shared-device-plugin-gpu | rdma_shared_device_plugin_gpu)
    DEPLOY_METHOD_FUNC="rdma_shared_device_plugin_gpu"
    ;;
*)
    echo "Unknown command: ${cmd}"
    print_help $0
    exit 1
    ;;
esac

subcmd="${2:-}"
case $subcmd in
sockperf | rdma_test | rdma-test | nccl_test_vllm_rdma | nccl-test-vllm-rdma) ;;
nccl_test_gpudirect_rdma | nccl-test-gpudirect-rdma | mpijob | debug | all) ;;
*)
    echo "Unknown subcommand: ${subcmd}"
    print_help $0
    exit 1
    ;;
esac

[[ ${subcmd} == "mpijob" ]] && create_topo_configmap
trap cleanup_cm EXIT

${DEPLOY_METHOD_FUNC}
