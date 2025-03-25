---
title: Network Operator
---

This guide details recommended configurations for Network Operator v25.1.0 to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs.

:::tip
This guide assumes a basic understanding of Network Operator and its role in Kubernetes clusters. Readers unfamiliar with the Network Operator are advised to review the official [Getting Started Guide](https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html) before proceeding. The concepts and recommended configurations presented here build on that foundation to enable RDMA over InfiniBand in AKS. This documentation is based on Network Operator v25.1.0.
:::

## Recommended Configuration

This guide details recommended configurations for Network Operator v25.1.0 to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs.

### Helm Values

Network Operator is deployed using [Helm](https://helm.sh/), and the [default Helm values](https://github.com/Mellanox/network-operator/blob/v25.1.0/deployment/network-operator/values.yaml) are recommended unless specific customizations are required. These defaults include [Node Feature Discovery (NFD)](https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/index.html), a critical dependency that labels nodes with hardware details (e.g., Mellanox NIC presence) for pod scheduling.

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm upgrade --install --create-namespace -n network-operator network-operator nvidia/network-operator --version v25.1.0
```

### NicClusterPolicy

Post-installation, create a `NicClusterPolicy` Custom Resource (CR) to define the desired state of networking components, such as Mellanox driver version and which device plugins to deploy. Two configurations are provided below: SR-IOV Device Plugin for exclusive Network Interface Card (NIC) access and RDMA Shared Device Plugin for shared access.

#### SR-IOV Device Plugin

The SR-IOV Device Plugin assigns each InfiniBand-enabled NIC (e.g., Mellanox ConnectX-6) to a single pod as a Kubernetes resource (`rdma/ib`). The number of available resources matches the count of physical NICs on the node (e.g., 1 NIC = 1 resource), ideal for workloads requiring maximum performance and isolation.

To deploy the above config, create a `NicClusterPolicy` CR with the following YAML:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/sriov-device-plugin
```

Example pod configuration:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: ib-pod
spec:
  containers:
  - name: ib
    image: images.my-company.example/app:v4
    resources:
      requests:
        rdma/ib: 8 # Claims 8 NIC; adjust to match node’s NIC count
      limits:
        rdma/ib: 8
```

#### RDMA Shared Device Plugin

The RDMA Shared Device Plugin enables multiple pods to share all InfiniBand NICs on a node, exposed as `rdma/shared_ib`. The resource count represents the maximum number of concurrent pods (default: 63 per node, configurable), not the NICs themselves, suiting resource-efficient workloads.

To deploy the above config, create a `NicClusterPolicy` CR with the following YAML:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/rdma-shared-device-plugin
```

Example pod configuration:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: ib-pod
spec:
  containers:
  - name: ib
    image: images.my-company.example/app:v4
    resources:
      requests:
        rdma/shared_ib: 1 # Claims 1 of 63 pod slots; all NICs accessible
      limits:
        rdma/shared_ib: 1
```

#### Recommendations

- **Maximum Performance**: Use the SR-IOV Device Plugin with one pod per node claiming all InfiniBand NICs (e.g., `rdma/ib: <NIC count>`), ensuring exclusive RDMA access for optimal throughput and isolation.
- **Resource Efficiency**: Use the RDMA Shared Device Plugin for multi-pod sharing. For GPUDirect RDMA workloads, note that if a pod claims `rdma/shared_ib: 1` and all GPUs (e.g., 8 on `Standard_ND96asr_v4`), no additional pods of the same type can schedule on that node due to GPU exhaustion, despite remaining RDMA slots.

## Order of Operations

The installation process follows this sequence:

1. **Network Operator Deployment**: The Helm chart installs the Network Operator, including its controller manager deployment to manage `NicClusterPolicy` reconciliation.
2. **Node Feature Discovery (NFD)**: Deployed as part of Network Operator Helm chart, NFD labels nodes with hardware details (e.g., Mellanox NICs) for certain pods to select nodes with specific hardware features.
3. **`NicClusterPolicy` Reconciliation**: Creates DaemonSets based on the CR:
    - `mofed-ubuntu22.04-ds`: Installs kernel drivers (e.g., Mellanox OFED and InfiniBand drivers) to enable RDMA over InfiniBand capabilities on the nodes.
    - `device-plugin`: Installs the SR-IOV Device Plugin and/or RDMA Shared Device Plugin, depending on the selected configuration. This plugin exposes the NICs as claimable resources in Kubernetes using the [Device Plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) framework.

## Frequently Asked Questions

### Why is secondary IP address assignment not required for RDMA over InfiniBand in AKS?

RDMA over InfiniBand operates below the TCP/IP stack, relying on direct memory access rather than IP-based networking. Tools like [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) and [whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts) for secondary network attachment and IPAM are not strictly required for RDMA over InfiniBand in AKS, as Device Plugins directly expose InfiniBand resources to pods.

If you wish to operate in the TCP/IP stack over the InfiniBand network, refer to the [NVIDIA Getting Started Guide for Kubernetes](https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html) for detailed instructions.
