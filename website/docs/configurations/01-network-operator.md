---
title: Network Operator
---

This guide details recommended configurations for Network Operator to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs.

:::tip
This guide assumes a basic understanding of Network Operator and its role in Kubernetes clusters. Readers unfamiliar with the Network Operator are advised to review the official [Getting Started Guide](https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html) before proceeding. The concepts and recommended configurations presented here build on that foundation to enable RDMA over InfiniBand in AKS.
:::

## Network Operator Deployment

### Operator

Network Operator is deployed using [Helm](https://helm.sh/), and the [default Helm values](https://github.com/Mellanox/network-operator/blob/v25.4.0/deployment/network-operator/values.yaml) are recommended unless specific customizations are required. These defaults include [Node Feature Discovery (NFD)](https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/index.html), a critical dependency that labels nodes with hardware details (e.g., Mellanox NIC presence) for pod scheduling.

Network operator deploys pods that require privileged access to the host system. To ensure proper operation, the `network-operator` namespace must be labeled with `pod-security.kubernetes.io/enforce=privileged`.

```bash
kubectl create ns network-operator
kubectl label --overwrite ns network-operator pod-security.kubernetes.io/enforce=privileged
```

Save the following YAML configuration to a file named `values.yaml`:

```yaml reference
https://github.com/Azure/aks-rdma-infiniband/blob/main/configs/values/network-operator/values.yaml
```

Deploy Network Operator with the following commands:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm upgrade --install \
  --create-namespace -n network-operator \
  network-operator nvidia/network-operator \
  -f values.yaml \
  --version v25.4.0
```

### Node Feature Rule

The Node Feature Discovery (NFD) component of the Network Operator is responsible for labeling nodes with hardware features. The default configuration includes a rule to label nodes with the presence of Mellanox NICs. This rule is essential for the proper functioning of the RDMA over InfiniBand setup.

```yaml reference
https://github.com/azure/aks-rdma-infiniband/blob/main/tests/setup-infra/network-operator-nfd.yaml
```

To deploy the above configuration, run the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/azure/aks-rdma-infiniband/refs/heads/main/tests/setup-infra/network-operator-nfd.yaml
```

Once above configuration takes effect, you can see that the nodes with Nvidia Mellanox NICs are labeled with label `feature.node.kubernetes.io/pci-15b3.present: true`.

```bash
kubectl get nodes -l "feature.node.kubernetes.io/pci-15b3.present=true" -o wide
```

## NicClusterPolicy

After installation of the network operator, create a `NicClusterPolicy` Custom Resource (CR) to define the desired state of networking components, such as Mellanox driver version and which device plugins to deploy.

### 1. SR-IOV Device Plugin

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
    securityContext:
      capabilities:
        # A pod without this will have a low locked memory value `# ulimit
        # -l` value of "64", this changes the value to "unlimited".
        add: ["IPC_LOCK"]
    resources:
      requests:
        rdma/ib: 8 # Claims 8 NIC; adjust to match node’s NIC count
      limits:
        rdma/ib: 8
```

### 2. RDMA Shared Device Plugin

The RDMA Shared Device Plugin enables multiple pods to share all InfiniBand NICs on a node, exposed as `rdma/shared_ib`. The resource count represents the maximum number of concurrent pods (default: 63 per node, configurable), not the NICs themselves, suiting resource-efficient workloads.

To deploy the above config, create a `NicClusterPolicy` CR with the following YAML:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/rdma-shared-device-plugin
```

Example pod configuration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ib-pod
spec:
  containers:
  - name: ib
    image: images.my-company.example/app:v4
    securityContext:
      capabilities:
        # A pod without this will have a low locked memory value `# ulimit
        # -l` value of "64", this changes the value to "unlimited".
        add: ["IPC_LOCK"]
    resources:
      requests:
        rdma/shared_ib: 1 # Claims 1 of 63 pod slots; all NICs accessible
      limits:
        rdma/shared_ib: 1
```

### 3. IP over InfiniBand (IPoIB)

IP over InfiniBand (IPoIB) is a network protocol that allows IP packets to be transmitted over InfiniBand networks. If the application is not enlightened to do RDMA out of the box, IPoIB can be used to enable IP-based communication over InfiniBand. This allows any off the shelf application to take advantage of the InfiniBand network.

In this case, each pod will be assigned a secondary IP address from the network subnet defined in [this configuration](https://github.com/Azure/aks-rdma-infiniband/blob/main/configs/nicclusterpolicy/ipoib/ipoib-network.yaml).

To enable IPoIB, create a `NicClusterPolicy` CR with the following YAML:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/ipoib
```

Example pod configuration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ib-pod
  annotations:
    # This name should match the IPoIBNetwork object we created earlier.
    # You can find this config by running `kubectl get IPoIBNetwork`.
    k8s.v1.cni.cncf.io/networks: aks-infiniband
spec:
  containers:
  - name: ib
    image: images.my-company.example/app:v4
```

### 4. Only Driver Installation

You can also create a `NicClusterPolicy` CR that only installs the Mellanox OFED driver without any device plugin.

:::danger
This configuration is not a recommended configuration as it does not provide any resource management or scheduling capabilities. This is useful for testing purposes only. Also note that applications have to run as privileged containers to access the InfiniBand devices.
:::

To deploy just the driver installation, create a `NicClusterPolicy` CR with the following YAML:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/base
```

Example pod configuration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ib-pod
spec:
  containers:
  - name: ib
    image: images.my-company.example/app:v4
    securityContext:
      privileged: true
```

### Recommendations

- **Maximum Performance**: Use the SR-IOV Device Plugin with one pod per node claiming all InfiniBand NICs (e.g., `rdma/ib: <NIC count>`), ensuring exclusive RDMA access for optimal throughput and isolation.
- **Resource Efficiency**: Use the RDMA Shared Device Plugin for multi-pod sharing. For GPUDirect RDMA workloads, note that if a pod claims `rdma/shared_ib: 1` and all GPUs (e.g., 8 on `Standard_ND96asr_v4`), no additional pods of the same type can schedule on that node due to GPU exhaustion, despite remaining RDMA slots.
- **Off the shelf Applications**: Use IPoIB for applications not RDMA-aware. This allows IP-based communication over InfiniBand, enabling existing applications to leverage the InfiniBand network.

## Order of Operations

The installation process follows this sequence:

1. **Network Operator Deployment**: The Helm chart installs the Network Operator, including its controller manager deployment to manage `NicClusterPolicy` reconciliation.
2. **Node Feature Discovery (NFD)**: Deployed as part of Network Operator Helm chart. The `NodeFeatureRule` CR helps NFD to label nodes with hardware details (e.g., Mellanox NICs) for certain pods to select nodes with specific hardware features.
3. **`NicClusterPolicy` Reconciliation**: Creates DaemonSets based on the CR:
    - `mofed-ubuntu22.04-ds`: Installs kernel drivers (e.g., Mellanox OFED and InfiniBand drivers) to enable RDMA over InfiniBand capabilities on the nodes.
    - `device-plugin`: Installs the SR-IOV Device Plugin and/or RDMA Shared Device Plugin, depending on the selected configuration. This plugin exposes the NICs as claimable resources in Kubernetes using the [Device Plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) framework.

## Frequently Asked Questions

### Why is secondary IP address assignment not required for RDMA over InfiniBand in AKS?

RDMA over InfiniBand operates below the TCP/IP stack, relying on direct memory access rather than IP-based networking. Tools like [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) and [whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts) for secondary network attachment and IPAM are not strictly required for RDMA over InfiniBand in AKS, as Device Plugins directly expose InfiniBand resources to pods.

If you wish to operate in the TCP/IP stack over the InfiniBand network, refer to the [NVIDIA Getting Started Guide for Kubernetes](https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html) for detailed instructions.
