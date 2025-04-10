---
title: Prerequisites
---

This section details the prerequisites for deploying an AKS cluster with support for Remote Direct Memory Access (RDMA) over InfiniBand, including optional configurations for GPUDirect RDMA.

## AKS Cluster

An active AKS cluster is required as the foundation for deploying RDMA over InfiniBand capabilities. The cluster serves as the Kubernetes environment where Network Operator and GPU Operator (if using GPUDirect RDMA) will be installed.

- **Requirement**: Create an AKS cluster using the [Azure Portal](https://portal.azure.com) or [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest). Ensure the cluster is running a supported Kubernetes version compatible with [Network Operator](https://docs.nvidia.com/networking/display/kubernetes2501/platform-support.html) and / or [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html).
- **Configuration**: The cluster must be deployed in a region that supports the required VM sizes with RDMA over InfiniBand capabilities.

To create an AKS cluster, use the following Azure CLI command as a starting point:

```bash
export AZURE_RESOURCE_GROUP="myResourceGroup"
export AZURE_REGION="eastus"
export CLUSTER_NAME="myAKSCluster"
export NODEPOOL_NAME="ibnodepool"
export NODEPOOL_NODE_COUNT="2"
export NODEPOOL_VM_SIZE="Standard_ND96asr_v4"

az group create \
  --name "${AZURE_RESOURCE_GROUP}" \
  --location "${AZURE_REGION}"

az aks create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${CLUSTER_NAME}" \
  --node-count 1 \
  --generate-ssh-keys
```

Additional nodepools will be added in the next step to meet specific hardware requirements.

## AKS Nodepools

The AKS cluster requires a dedicated nodepool configured to support RDMA over InfiniBand. For AI workloads leveraging GPUDirect RDMA, GPU support is also necessary.

| Requirement                | Recommended Configuration                                                                                                                                                                                                                                                                                                                                                                                     | Description                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Minimum Nodes**          | At least 2 nodes                                                                                                                                                                                                                                                                                                                                                                                              | Enables cross-node communication for RDMA over InfiniBand; more nodes for scaling                         |
| **Operating System**       | Ubuntu                                                                                                                                                                                                                                                                                                                                                                                                        | Well-supported by NVIDIA drivers and software stack; other OS options may be available                    |
| **Hardware**               | [Mellanox ConnectX NICs](https://www.nvidia.com/en-us/networking/ethernet-adapters/)                                                                                                                                                                                                                                                                                                                          | High-performance network interface cards (NICs) for RDMA over InfiniBand support                          |
| **VM Size** (with GPUs)    | [ND-series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nd-family)                                                                                                                                                                                                                                                                                                         | NVIDIA GPU-enabled VMs with InfiniBand support; e.g., `Standard_ND96asr_v4` or `Standard_ND96isr_H100_v5` |
| **VM Size** (without GPUs) | [RDMA capable instances](https://learn.microsoft.com/en-us/azure/virtual-machines/setup-infiniband#rdma-capable-instances) like [HBv2](https://learn.microsoft.com/en-us/azure/virtual-machines/hbv2-series-overview), [HBv3](https://learn.microsoft.com/en-us/azure/virtual-machines/hbv3-series-overview) or [HBv4](https://learn.microsoft.com/en-us/azure/virtual-machines/hbv4-series-overview) series. | High performance compute machines with Infiniband support; e.g., `Standard_HB120rs_v3`                    |
| **GPUDirect RDMA**         | Optional; requires GPU-enabled VMs (e.g., ND-series with A100 or H100 GPUs)                                                                                                                                                                                                                                                                                                                                   | Enables direct GPU-to-GPU communication; omit GPUs for non-GPUDirect RDMA use cases                       |

### Register AKS Infiniband Support Feature

To ensure that the machines in the nodepool land on the same physical Infiniband network, you need to register the AKS Infiniband Support feature.

```bash
az feature register --name AKSInfinibandSupport --namespace Microsoft.ContainerService
az feature show \
  --namespace "Microsoft.ContainerService" \
  --name AKSInfinibandSupport
```

### Nodepool with GPUs

#### GPU Operator Managed GPU Driver

To create an AKS nodepool **without** GPU Driver installation by AKS and with [GPU Operator](../configurations/02-gpu-operator.md), use the following command:

```bash
az extension add -n aks-preview
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${CLUSTER_NAME}" \
  --name "${NODEPOOL_NAME}" \
  --node-count "${NODEPOOL_NODE_COUNT}" \
  --node-vm-size "${NODEPOOL_VM_SIZE}" \
  --os-sku Ubuntu \
  # highlight-next-line
  --skip-gpu-driver-install
```

#### AKS Managed GPU Driver

To create an AKS nodepool **with** GPU Driver installation by AKS and **without** GPU Operator, use the following command:

```bash
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${CLUSTER_NAME}" \
  --name "${NODEPOOL_NAME}" \
  --node-count "${NODEPOOL_NODE_COUNT}" \
  --node-vm-size "${NODEPOOL_VM_SIZE}" \
  --os-sku Ubuntu
```

### Nodepool without GPUs

To create an AKS nodepool backed by non-GPU VMs, use the following command:

```bash
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${CLUSTER_NAME}" \
  --name "${NODEPOOL_NAME}" \
  --node-count "${NODEPOOL_NODE_COUNT}" \
  --node-vm-size "${NODEPOOL_VM_SIZE}" \
  --os-sku Ubuntu
```

## Appendix

### Understanding VM Size Naming Convention of ND-series

Azure VM sizes use a naming convention to indicate their hardware capabilities. The table below explains the components of VM sizes relevant to RDMA over InfiniBand, and GPUDirect RDMA support in AKS, with examples from the ND-series.

| Component  | Meaning                           |
| ---------- | --------------------------------- |
| **N**      | NVIDIA GPU-enabled                |
| **D**      | Training and inference capable    |
| **r**      | RDMA capable                      |
| **a**      | AMD CPUs                          |
| **s**      | Premium storage capable           |
| **vX**     | Version/generation (e.g., v4, v5) |
| **Number** | vCPUs (e.g., 96)                  |
| **GPU**    | Specific GPU model (e.g., H100)   |

#### Examples

- `Standard_ND96asr_v4`: NVIDIA GPUs (N), Training and inference (D), AMD CPUs (a), premium storage (s), RDMA (r), A100 GPUs, 96 vCPUs, version 4 (v4).
- `Standard_ND96isr_H100_v5`: NVIDIA GPUs (N), Training and inference (D), RDMA (r), premium storage (s), H100 GPUs, 96 vCPUs, version 5 (v5).
