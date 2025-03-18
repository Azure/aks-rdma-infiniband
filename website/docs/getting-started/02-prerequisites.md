---
title: Prerequisites
---

This section details the prerequisites for deploying an AKS cluster with support for high-speed InfiniBand networking and Remote Direct Memory Access (RDMA), including optional configurations for GPUDirect RDMA.

## AKS Nodepools

An active AKS cluster is required as the foundation for deploying RDMA over InfiniBand capabilities. The cluster serves as the Kubernetes environment where Network Operator and GPU Operator (if using GPUDirect RDMA) will be installed.

- **Requirement**: Create an AKS cluster using the [Azure Portal](https://portal.azure.com) or [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest). Ensure the cluster is running a supported Kubernetes version compatible with [Network Operator](https://docs.nvidia.com/networking/display/kubernetes2501/platform-support.html) and [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html).
- **Configuration**: The cluster must be deployed in a region that supports the required VM sizes with RDMA over InfiniBand capabilities.

To create an AKS cluster, use the following Azure CLI command as a starting point:

```bash
export AZURE_RESOURCE_GROUP="myResourceGroup"
export CLUSTER_NAME="myAKSCluster"
export NODEPOOL_NAME="ibnodepool"
export NODEPOOL_NODE_COUNT="2"
export NODEPOOL_VM_SIZE="Standard_ND96asr_v4"

az aks create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${CLUSTER_NAME}" \
  --node-count 1 \
  --generate-ssh-keys
```

Additional nodepools will be added in the next step to meet specific hardware requirements.

### Requirements

The AKS cluster requires a dedicated nodepool configured to support InfiniBand networking and RDMA. For AI workloads leveraging GPUDirect RDMA, GPU support is also necessary.

| Requirement          | Recommended Configuration                                                                             | Description                                                                                               |
| -------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Minimum Nodes**    | At least 2 nodes                                                                                      | Enables cross-node communication for RDMA over InfiniBand; more nodes for scaling                         |
| **Operating System** | Ubuntu                                                                                                | Well-supported by NVIDIA drivers and software stack; other OS options may be available                    |
| **Hardware**         | [Mellanox ConnectX NICs](https://www.nvidia.com/en-us/networking/ethernet-adapters/)                  | High-performance network interface cards (NICs) for RDMA over InfiniBand support                          |
| **VM Size**          | [ND-series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nd-family) | NVIDIA GPU-enabled VMs with InfiniBand support; e.g., `Standard_ND96asr_v4` or `Standard_ND96isr_H100_v5` |
| **GPUDirect RDMA**   | Optional; requires GPU-enabled VMs (e.g., ND-series with A100 or H100 GPUs)                           | Enables direct GPU-to-GPU communication; omit GPUs for non-GPUDirect RDMA use cases                       |

To configure an AKS nodepool with RDMA over InfiniBand support - either without GPUs or with a GPU-enabled VM size using the AKS-managed GPU driver installation, use the following command:

```bash
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${CLUSTER_NAME}" \
  --name "${NODEPOOL_NAME}" \
  --node-count "${NODEPOOL_NODE_COUNT}" \
  --node-vm-size "${NODEPOOL_VM_SIZE}" \
  --os-sku Ubuntu
```

To create a GPU nodepool **without** GPU Driver installation, use the following command (see below section for more details):

```bash
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

### Skip GPU Driver Installation

:::info
Read more about the GPU driver installation options in AKS and the NVIDIA GPU Operator in the [AKS documentation](https://learn.microsoft.com/en-us/azure/aks/gpu-cluster?tabs=add-ubuntu-gpu-node-pool) and the [GPU Operator documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html).
:::

When provisioning GPU nodepools in an AKS cluster, the cluster administrator has the option to either rely on the default GPU driver installation managed by AKS or via GPU Operator. This decision impacts cluster setup, maintenance, and compatibility.

|                | **Without NVIDIA GPU Operator (Default)**                         | **With NVIDIA GPU Operator (Skip GPU Driver)**                              |
| -------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Automation** | AKS-managed drivers; no automation for other components           | Automates driver, device plugins, and container runtimes via GPU Operator   |
| **Complexity** | Default: Minimal setup, no flexibility; Manual: High setup effort | Moderate setup (deploy operator); simplified ongoing management             |
| **Support**    | Fully supported by AKS; no preview features                       | `--skip-gpu-driver-install` is a preview feature; limited support available |

#### Recommendations

For GPUDirect RDMA over InfiniBand, use the NVIDIA GPU Operator with `--skip-gpu-driver-install` when creating the nodepool to leverage GPU Operator's automation and management capabilities. This approach simplifies the deployment of GPU drivers, device plugins, and container runtimes, ensuring compatibility with the latest NVIDIA stack.

Opt for AKS-managed driver for simpler GPU tasks without GPUDirect RDMA needs.

## Appendix

### Understanding VM Size Naming Conventions

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
