#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

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
    aks_infiniband_support="az feature show \
        --namespace "Microsoft.ContainerService" \
        --name AKSInfinibandSupport -o tsv --query 'properties.state'"

    # Until the output of the above command is not "Registered", keep running the command.
    while [[ "$(eval $aks_infiniband_support)" != "Registered" ]]; do
        az feature register --name AKSInfinibandSupport --namespace Microsoft.ContainerService
        echo "Waiting for the feature 'AKSInfinibandSupport' to be registered..."
        sleep 10
    done

    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
    helm repo update

    helm upgrade -i \
        --wait \
        --create-namespace \
        -n network-operator \
        network-operator \
        nvidia/network-operator \
        --set nfd.deployNodeFeatureRules=false "$@"

    kubectl apply -f ${SCRIPT_DIR}/network-operator-nfd.yaml
}

function install_gpu_operator() {
    kubectl create ns gpu-operator || true
    kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

    helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
    helm repo update

    # See if NFD is already deployed. This means that the network operator was deployed before.
    NFD_PODS_COUNT="$(kubectl get pods \
        -A -l app.kubernetes.io/name=node-feature-discovery \
        --no-headers | wc -l)"

    HELM_CHART_FLAGS=""
    if [[ "${NFD_PODS_COUNT}" -gt 0 ]]; then
        HELM_CHART_FLAGS="--set nfd.enabled=false"
    fi

    helm upgrade -i \
        --wait \
        -n gpu-operator \
        --create-namespace \
        gpu-operator \
        nvidia/gpu-operator \
        --set dcgmExporter.serviceMonitor.enabled="true" ${HELM_CHART_FLAGS}

    # Wait until the output of the command "cat foo" is empty
    while [ ! "$(kubectl get pods -n gpu-operator | grep Completed)" ]; do
        echo "Waiting for pods to be ready..."
        sleep 5
    done

    echo -e '\nGPUs on nodes:\n'
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
    echo "Usage: $0 deploy-aks|add-nodepool|install-network-operator|install-gpu-operator|all"
    exit 1
    ;;
esac
