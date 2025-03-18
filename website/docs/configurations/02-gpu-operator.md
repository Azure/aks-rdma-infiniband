---
title: GPU Operator
---

:::tip
This guide assumes a basic understanding of GPU Operator and its role in Kubernetes clusters. Readers unfamiliar with GPU Operator are advised to review the official [guide](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html) before proceeding. The concepts and recommended configurations presented here build on that foundation to enable GPU workload and GPUDirect RDMA in AKS. This documentation is based on GPU Operator v24.9.2.
:::

## Recommended Configuration

This guide details recommended configurations for GPU Operator v24.9.2 to enable GPU workload, with specific settings for GPUDirect RDMA integration.

### Skip GPU Driver Installation

:::info
Read more about the GPU driver installation options in AKS and the NVIDIA GPU Operator in the [AKS documentation](https://learn.microsoft.com/en-us/azure/aks/gpu-cluster?tabs=add-ubuntu-gpu-node-pool) and the [GPU Operator documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html).
:::

:::danger
AKS-managed GPU drivers and the NVIDIA GPU Operator are **mutually exclusive** and cannot coexist. When you create a nodepool **without** the `--skip-gpu-driver-install` flag, AKS provisions it with a node image that includes pre-installed NVIDIA drivers and the NVIDIA container runtime. Installing GPU Operator subsequently replaces this setup by deploying its own `nvidia-container-toolkit`, overriding the AKS-managed configuration. Upon uninstalling GPU Operator, the toolkit cannot revert to the original AKS containerd configuration, as it lacks awareness of the prior state, potentially disrupting the node’s container runtime and impairing workload execution.
:::

When provisioning GPU nodepools in an AKS cluster, the cluster administrator has the option to either rely on the default GPU driver installation managed by AKS or via GPU Operator. This decision impacts cluster setup, maintenance, and compatibility.

|                | **AKS-managed GPU Driver (Without GPU Operator)**                                  | **GPU Operator-managed GPU Driver (`--skip-gpu-driver-install`)**                         |
| -------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Automation** | AKS-managed drivers; cluster administrator needs to manually deploy device plugins | Automates installation of driver, device plugins, and container runtimes via GPU Operator |
| **Complexity** | Simple, no additional components except device plugins                             | More complex, requires GPU Operator and additional components                             | Moderate setup (deploy operator); simplified ongoing management |
| **Support**    | Fully supported by AKS; no preview features                                        | `--skip-gpu-driver-install` is a preview feature; limited support available               |

#### Recommendations

For GPUDirect RDMA over InfiniBand, use GPU Operator with `--skip-gpu-driver-install` when creating the nodepool to leverage GPU Operator's automation and management capabilities. This approach enables self-management of GPU drivers, device plugins, and container runtimes via GPU Operator, ensuring compatibility with the latest NVIDIA stack. This guide assumes the use of GPU Operator with `--skip-gpu-driver-install` for the GPU driver installation:

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

Opt for AKS-managed driver and skip GPU Operator installation for simpler GPU tasks without GPUDirect RDMA needs.

### Helm Values

GPU Operator is deployed using [Helm](https://helm.sh/), and the [default Helm values](https://github.com/NVIDIA/gpu-operator/blob/v24.9.2/deployments/gpu-operator/values.yaml) are customized to align with the Network Operator and AKS requirements. Key adjustments to the Helm values disable redundant components such as NFD and enable RDMA support.

Save the following YAML configuration to a file named `gpu-operator-values.yaml`:

```yaml reference
https://github.com/Azure/aks-rdma-infiniband/blob/main/configs/gpu-operator/values.yaml
```

Deploy GPU Operator with the following command:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm upgrade --install --create-namespace -n gpu-operator gpu-operator nvidia/gpu-operator -f values.yaml
```

### GPUDirect RDMA

Once GPU Operator and its operands are installed, configure pods to claim both GPUs and InfiniBand resources created from one of the [device plugins managed via Network Operator](network-operator#nicclusterpolicy). Below is an example for a GPUDirect RDMA workload using [SR-IOV Device Plugin](network-operator#sr-iov-device-plugin):

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: gpudirect-rdma
spec:
  containers:
  - name: gpudirect-rdma
    image: images.my-company.example/app:v4
    resources:
      requests:
        nvidia.com/gpu: 8 # Claims all GPUs on the node
        rdma/ib: 8        # Claims 8 NIC; adjust to match node’s NIC count
      limits:
        nvidia.com/gpu: 8
        rdma/ib: 8
```

Below is an example for a GPUDirect RDMA workload using [RDMA Shared Device Plugin](network-operator#rdma-shared-device-plugin):

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: gpudirect-rdma
spec:
  containers:
  - name: gpudirect-rdma
    image: images.my-company.example/app:v4
    resources:
      requests:
        nvidia.com/gpu: 8 # Claims all GPUs on the node
        rdma/shared_ib: 1 # Claims 1 of 63 pod slots; all NICs accessible
      limits:
        nvidia.com/gpu: 8
        rdma/shared_ib: 1
```

## Order of Operations

The installation process follows this sequence:

1. **GPU Operator Deployment**: The Helm chart installs GPU Operator, including its controller manager deployment to manage `ClusterPolicy` reconciliation.
2. **`ClusterPolicy` Reconciliation**: The GPU Operator controller manager reconciles `ClusterPolicy`, a custom resource that defines the desired state of GPU Operator and its components. The operator continuously monitors the cluster for changes and ensures that the actual state matches the desired state defined in the `ClusterPolicy`. The operator creates the following notable DaemonSets:
    - `nvidia-driver-daemonset`: Installs NVIDIA drivers on GPU nodes, blocking other components until complete, as the container runtime depends on it.
    - `nvidia-container-toolkit-daemonset`: Configures containerd with `nvidia-container-runtime` as the default container runtime for creating containers going foward. Creates `nvidia` [RuntimeClass](https://kubernetes.io/docs/concepts/containers/runtime-class/), enabling subsequent deployments.
    - `nvidia-device-plugin-daemonset`: Registers GPUs as claimable node resources (`nvidia.com/gpu`) via the [Device Plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) framework.
    - `nvidia-dcgm-exporter`: Exports GPU telemetry as Prometheus metrics, enabling monitoring of GPU utilization and other metrics.
    - `nvidia-operator-validator`: Validates GPU Operator installation and configuration, ensuring that all components are functioning correctly.
    - `gpu-feature-discovery` (GFD): Discovers GPU features and labels nodes with GPU attributes (e.g., `nvidia.com/gpu.product=NVIDIA-A100-SXM4-40G`) for scheduling.
