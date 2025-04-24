#!/usr/bin/env bash

set -euo pipefail

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

NETWORK_OPERATOR_NS="network-operator"

function wait_until_mofed_is_ready() {
    mofed_label="nvidia.com/ofed-driver"

    # Wait until the number of nodes with label 'network.nvidia.com/operator.mofed.wait: "false"' is equal to the number of mofed pods.
    while true; do
        # Get the mofed pod count
        mofed_pods_count="$(kubectl get pods \
            -n ${NETWORK_OPERATOR_NS} \
            -l ${mofed_label} \
            --no-headers | wc -l)"

        # Get the number of nodes with label 'network.nvidia.com/operator.mofed.wait: "false"'
        nodes_with_mofed_wait_false="$(kubectl get nodes \
            -l "network.nvidia.com/operator.mofed.wait=false" \
            --no-headers | wc -l)"

        if [[ "${mofed_pods_count}" -gt 0 && "${mofed_pods_count}" -eq "${nodes_with_mofed_wait_false}" ]]; then
            echo "✅ MOFED driver is successfully installed on all nodes."
            break
        fi

        [[ "${mofed_pods_count}" -eq 0 ]] && echo "⏳ Waiting for mofed pods to show up..."
        echo "⏳ Waiting for all nodes to be labeled 'network.nvidia.com/operator.mofed.wait=false' ..."
        sleep 10
    done
}

function wait_until_sriov_is_ready() {
    ds="network-operator-sriov-device-plugin"
    _wait_until_ds_is_ready "${NETWORK_OPERATOR_NS}" "${ds}"
    # Some times even when the pods report running, the devices take time to show up, so give it some time.
    sleep 10

    echo -e '\nRDMA IB devices on nodes:\n'
    rdma_ib_on_nodes_cmd="kubectl get nodes -o json | jq -r '.items[] | {name: .metadata.name, \"rdma/ib\": .status.allocatable[\"rdma/ib\"]}'"
    echo "$ ${rdma_ib_on_nodes_cmd}"
    eval "${rdma_ib_on_nodes_cmd}"
}

function wait_until_rdma_is_ready() {
    ds="rdma-shared-dp-ds"
    _wait_until_ds_is_ready "${NETWORK_OPERATOR_NS}" "${ds}"
    # Some times even when the pods report running, the devices take time to show up, so give it some time.
    sleep 10

    echo -e '\nRDMA Shared IB devices on nodes:\n'
    rdma_ib_on_nodes_cmd="kubectl get nodes -o json | jq -r '.items[] | {name: .metadata.name, \"rdma/shared_ib\": .status.allocatable[\"rdma/shared_ib\"]}'"
    echo "$ ${rdma_ib_on_nodes_cmd}"
    eval "${rdma_ib_on_nodes_cmd}"
}

function _check_if_all_pods_in_ds_are_ready() {
    namespace="${1}"
    ds_name="${2}"

    ready=$(kubectl get daemonset "$ds_name" -n "$namespace" -o jsonpath='{.status.numberReady}')
    desired=$(kubectl get daemonset "$ds_name" -n "$namespace" -o jsonpath='{.status.desiredNumberScheduled}')

    [[ "$ready" -eq "$desired" ]] && return 0

    return 1
}

function _wait_until_ds_is_ready() {
    namespace="${1}"
    ds_name="${2}"

    while true; do
        if _check_if_all_pods_in_ds_are_ready "${namespace}" "${ds_name}"; then
            echo "✅ DaemonSet '$ds_name' in namespace '${namespace}' is ready."
            break
        fi

        echo "⏳ Waiting for DaemonSet '$ds_name' in namespace '${namespace}' to be ready..."
        sleep 5
    done
}

function wait_until_ipoib_is_ready() {
    ds_list=(
        cni-plugins-ds
        kube-ipoib-cni-ds
        kube-multus-ds
        whereabouts
    )

    for ds in "${ds_list[@]}"; do
        _wait_until_ds_is_ready "${NETWORK_OPERATOR_NS}" "${ds}"
    done

    echo "✅ All DaemonSets are ready!"
}

function ipoib_add_ep_ip() {
    while true; do
        ep_ip=$(kubectl get pods -l role=leader -o json | jq -r '
        .items[]
            | select(.metadata.annotations["k8s.v1.cni.cncf.io/network-status"] != null)
            | .metadata.annotations["k8s.v1.cni.cncf.io/network-status"]
            | fromjson
            | map(select(.name == "default/aks-infiniband"))[0]
            | if . == null then
                error("Network name is not default/aks-infiniband")
              else
                .ips[0]
              end')

        # Break only if ep_ip is not empty
        if [[ -n "${ep_ip}" ]]; then
            echo "✅ Found leader pod Infiniband IP: ${ep_ip}".
            break
        fi
        echo "⏳ Waiting for leader pod to be ready..."
        sleep 5
    done

    kubectl apply -f - <<EOF
apiVersion: v1
kind: Endpoints
metadata:
  name: leader-ib
subsets:
  - addresses:
      - ip: ${ep_ip}
EOF
}

function create_topo_configmap() {
    topo_file_name
    kubectl create configmap nvidia-topology \
        --from-file="topo.xml=${SCRIPT_DIR}/nvidia-topology/${TOPO_FILE_NAME}" \
        --dry-run=client -o yaml | kubectl apply -f -
}

function mpi_job_number_of_processes() {
    NUMBER_OF_PROCESSES=$((GPU_PER_NODE_NUMBER * 2))
}

function find_gpu_per_node() {
    if [[ -z "$NODE_POOL_VM_SIZE" ]]; then
        echo "❌ Environment variable NODE_POOL_VM_SIZE not set" >&2
        exit 1
    fi

    GPU_PER_NODE_NUMBER=$(kubectl get nodes -o json |
        jq -r --arg NODE_TYPE "$NODE_POOL_VM_SIZE" '
        .items
        | map(select((.metadata.labels["node.kubernetes.io/instance-type"] | ascii_downcase) == ($NODE_TYPE | ascii_downcase)))
        | .[0].status.allocatable["nvidia.com/gpu"] // "0"
      ')

    if [[ "$GPU_PER_NODE_NUMBER" == "0" ]]; then
        echo "❌ No GPUs found on nodes of type: $NODE_POOL_VM_SIZE" >&2
        exit 1
    fi
}

function cleanup_cm() {
    kubectl delete configmap nvidia-topology
}

function topo_file_name() {
    # The topo files in the nvidia-topology folder are added from here:
    # https://github.com/Azure/azhpc-images/tree/4a4565a0c0aa9d6944c53420155936061b9c3a98/topology

    vm_family=""
    vm_version=""

    if [[ "$NODE_POOL_VM_SIZE" =~ (ND|NC).*v([0-9]+)$ ]]; then
        vm_family="${BASH_REMATCH[1]}"
        vm_version="v${BASH_REMATCH[2]}"
    fi

    case "${vm_family}" in
    "ND")
        case "${vm_version}" in
        "v2")
            export TOPO_FILE_NAME="ndv2-topo.xml"
            ;;
        "v4")
            export TOPO_FILE_NAME="ndv4-topo.xml"
            ;;
        "v5")
            export TOPO_FILE_NAME="ndv5-topo.xml"
            ;;
        *)
            echo "❌ Unknown ND family version: $vm_version. Only ND v2, v4, and v5 are supported."
            exit 1
            ;;
        esac
        ;;
    "NC")
        case "${vm_version}" in
        "v4")
            export TOPO_FILE_NAME="ncv4-topo.xml"
            ;;
        *)
            echo "❌ Unknown NC family version: $vm_version. Only NC v4 is supported."
            exit 1
            ;;
        esac
        ;;
    *)
        echo "❌ Unknown VM family: $vm_family. Only ND and NC are supported."
        exit 1
        ;;
    esac
}

function fail_on_job_failure() {
    # As soon as the job fails, print the logs and exit with an error.
    while true; do
        JOB_STATUS="$(kubectl get job -l "${1}" -n "${2}" -o jsonpath='{.items[*].status.conditions[?(@.type=="Failed")].status}')"
        if [[ "${JOB_STATUS}" == "True" ]]; then
            echo
            echo "❌ Job '${1}' in namespace '${2}' failed. Printing logs..."
            echo
            kubectl logs -n "$2" "$(kubectl get pods -n "$2" -l "${1}" -o jsonpath='{.items[0].metadata.name}')" --all-containers
            exit 1
        fi

        JOB_STATUS="$(kubectl get job -l "${1}" -n "${2}" -o jsonpath='{.items[*].status.conditions[?(@.type=="Complete")].status}')"
        if [[ "${JOB_STATUS}" == "True" ]]; then
            echo
            echo "✅ Job '${1}' in namespace '${2}' succeeded. Printing logs..."
            echo
            kubectl logs -n "$2" "$(kubectl get pods -n "$2" -l "${1}" -o jsonpath='{.items[0].metadata.name}')" --all-containers
            break
        fi

        echo "⏳ Waiting for job with label '${1}' in namespace '${2}' to complete..."
        sleep 5
    done
}

function print_help() {
    # Print multiline
    cat <<EOF
AKS RDMA Infiniband Test Suite

Usage:
  $1 [command] [subcommand]

Available Commands (GPU):
  sriov-nic-policy-gpu            Run a test with SR-IOV shared device plugin
  rdma-shared-device-plugin-gpu   Run a test with RDMA shared device plugin
  ipoib-nic-policy-gpu            Run a test with IP over IB
  root-nic-policy-gpu             Run a test with no shared device plugin

Available Commands (non-GPU):
  sriov-nic-policy                Run a test with SR-IOV shared device plugin without GPU
  rdma-shared-device-plugin       Run a test with RDMA shared device plugin wihtout GPU
  ipoib-nic-policy                Run a test with IP over IB without GPU
  root-nic-policy                 Run a test with no shared device plugin without GPU

Available Subcommands:
  mpijob                        Run MPI job to see the total speed
  rdma-test                     Run RDMA tests with IB utility
  nccl-test-gpudirect-rdma      Run Python based NCCL test to verify GPUDirect RDMA
  nccl-test-vllm-rdma           Run Python based NCCL tests with vLLM
  sockperf                      Run tests with sockperf utility
  all                           Run all tests in the order sockperf, rdma-test and nccl-tests
  debug                         The tests sleep infinitely for debugging
EOF
}
