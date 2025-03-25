#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../scenarios/util.sh"

# Check if the DEBUG env var is set to true
if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

# RG specific variables
: "${AZURE_RESOURCE_GROUP:=ib-test}"

# AKS specific variables
: "${CLUSTER_NAME:=ib-aks-cluster}"
: "${USER_NAME:=azureuser}"

# deploy_aks creates a resource gropu and a new AKS cluster with the provided
# arguments. You can provide additional arguments to the function. For example a
# call would look like this: `deploy_aks --enable-addons monitoring`
function deploy_aks() {
    # RG specific variables
    : "${AZURE_REGION:?Environment variable AZURE_REGION must be set}"

    az group create \
        --name "${AZURE_RESOURCE_GROUP}" \
        --location "${AZURE_REGION}"

    az aks create \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --name "${CLUSTER_NAME}" \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --enable-managed-identity \
        --node-count 1 \
        --location "${AZURE_REGION}" \
        --generate-ssh-keys \
        --admin-username "${USER_NAME}" \
        --os-sku Ubuntu "$@"
}

# add_nodepool adds a new node pool to the AKS cluster. You can provide additional
# arguments to the function. For example a call would look like this:
# `add_nodepool --skip-gpu-driver-install --node-osdisk-size 48`
function add_nodepool() {
    # Node pool specific variables
    : "${NODE_POOL_VM_SIZE:?Environment variable NODE_POOL_VM_SIZE must be set}"
    : "${NODE_POOL_NAME:=ibnodepool}"
    : "${NODE_POOL_NODE_COUNT:=2}"

    az extension add --name aks-preview || true
    az extension update --name aks-preview || true

    aks_infiniband_support="az feature show \
        --namespace "Microsoft.ContainerService" \
        --name AKSInfinibandSupport -o tsv --query 'properties.state'"

    # Until the output of the above command is not "Registered", keep running the command.
    while [[ "$(eval $aks_infiniband_support)" != "Registered" ]]; do
        az feature register --name AKSInfinibandSupport --namespace Microsoft.ContainerService
        echo "⏳ Waiting for the feature 'AKSInfinibandSupport' to be registered..."
        sleep 10
    done

    az aks nodepool add \
        --name "${NODE_POOL_NAME}" \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --cluster-name "${CLUSTER_NAME}" \
        --node-count "${NODE_POOL_NODE_COUNT}" \
        --node-vm-size "${NODE_POOL_VM_SIZE}" "$@"
}

# download_aks_credentials downloads the AKS credentials to the local machine. You
# can provide additional arguments to the function. For example a call would look
# like this: `download_aks_credentials --overwrite-existing`
function download_aks_credentials() {
    az aks get-credentials \
        --resource-group "${AZURE_RESOURCE_GROUP}" \
        --name "${CLUSTER_NAME}" "$@"
}

# install_network_operator installs the NVIDIA network operator on the AKS
# cluster. You can provide additional arguments to modify the network operator
# values file with `--set key=value`. For example a call would like this:
# `install_network_operator --set key=value`
function install_network_operator() {
    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
    helm repo update

    # Find latest version of network operator: https://github.com/Mellanox/network-operator/releases
    helm upgrade -i \
        --wait \
        --create-namespace \
        -n network-operator \
        --values ${SCRIPT_DIR}/../../configs/values/network-operator/values.yaml \
        network-operator \
        nvidia/network-operator \
        --version v25.1.0

    kubectl apply -f ${SCRIPT_DIR}/network-operator-nfd.yaml
    kubectl apply -k "${SCRIPT_DIR}/../../configs/nicclusterpolicy/base"
    wait_until_mofed_is_ready
}

function install_gpu_operator() {
    gpu_operator_ns="gpu-operator"
    kubectl create ns "${gpu_operator_ns}" || true
    kubectl label --overwrite ns "${gpu_operator_ns}" pod-security.kubernetes.io/enforce=privileged

    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
    helm repo update

    # Find latest version of the GPU operator: https://github.com/NVIDIA/gpu-operator/releases
    helm upgrade -i \
        --wait \
        -n "${gpu_operator_ns}" \
        --create-namespace \
        --values ${SCRIPT_DIR}/../../configs/values/gpu-operator/values.yaml \
        gpu-operator \
        nvidia/gpu-operator \
        --version v24.9.2

    cuda_validator_label="app=nvidia-cuda-validator"

    echo "⏳ Waiting for all pods with label $cuda_validator_label in namespace $gpu_operator_ns to complete..."
    while true; do
        pods_json=$(kubectl get pods -n "$gpu_operator_ns" -l "$cuda_validator_label" -o json)

        total=$(echo "${pods_json}" | jq '.items | length')
        succeeded=$(echo "${pods_json}" | jq '[.items[] | select(.status.phase == "Succeeded")] | length')

        if [ "${total}" -eq "${succeeded}" ] && [ "${total}" -ne 0 ]; then
            echo "✅ All ${total} pods have completed successfully."
            break
        else
            echo "⏳ Waiting for nvidia-cuda-validator, ${succeeded}/${total} pods completed..."
            sleep 5
        fi
    done

    echo -e '\n🤖 GPUs on nodes:\n'
    gpu_on_nodes_cmd="kubectl get nodes -o json | jq -r '.items[] | {name: .metadata.name, \"nvidia.com/gpu\": .status.allocatable[\"nvidia.com/gpu\"]}'"
    echo "$ ${gpu_on_nodes_cmd}"
    eval "${gpu_on_nodes_cmd}"
}

PARAM="${1:-}"
case $PARAM in
deploy-aks)
    deploy_aks
    download_aks_credentials --overwrite-existing
    ;;
add-nodepool)
    add_nodepool --skip-gpu-driver-install
    ;;
install-network-operator)
    install_network_operator
    ;;
install-gpu-operator)
    install_gpu_operator
    ;;
all)
    deploy_aks
    download_aks_credentials --overwrite-existing
    add_nodepool
    install_network_operator
    ;;
*)
    echo "🛠️ Usage: $0 deploy-aks|add-nodepool|install-network-operator|install-gpu-operator|all"
    exit 1
    ;;
esac
