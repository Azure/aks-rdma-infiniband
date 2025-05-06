---
title: GPU Drivers
---

This guide details recommended configurations to enable GPU drivers with specific settings for GPUDirect RDMA integration. Users can choose between AKS-managed GPU drivers or the NVIDIA GPU Operator for driver lifecycle management. The guide also provides examples of how to configure pods to utilize GPUDirect RDMA with different device plugin options.

## GPU Drivers: AKS-managed vs. GPU Operator-managed

When provisioning GPU nodepools in an AKS cluster, the cluster administrator has the option to either rely on the default GPU driver installation managed by AKS or via GPU Operator. This decision impacts cluster setup, maintenance, and compatibility.

|                | **AKS-managed GPU Driver (Without GPU Operator)**                                  | **GPU Operator-managed GPU Driver (`--gpu-driver none`)**                                 |
|----------------|------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| **Automation** | AKS-managed drivers; cluster administrator needs to manually deploy device plugins | Automates installation of driver, device plugins, and container runtimes via GPU Operator |
| **Complexity** | Simple, no additional components except device plugins                             | More complex, requires GPU Operator and additional components                             |
| **Support**    | Fully supported by AKS; no preview features                                        | No AKS support; driver install and maintenance with self-managed NVIDIA GPU Operator      |

:::danger
AKS-managed GPU drivers and the NVIDIA GPU Operator managed GPU drivers are **mutually exclusive** and cannot coexist. When you create a nodepool **without** setting the `--gpu-driver` field to `none`, AKS provisions the nodepool with NVIDIA drivers and the NVIDIA container runtime. Installing GPU Operator subsequently replaces this setup by deploying its own `nvidia-container-toolkit`, overriding the AKS-managed configuration. Upon uninstalling GPU Operator, the toolkit cannot revert to the original AKS containerd configuration, as it lacks awareness of the prior state, potentially disrupting the node’s container runtime and impairing workload execution.
:::

:::info
Read more about the GPU driver installation options in AKS and the NVIDIA GPU Operator in the [AKS documentation](https://learn.microsoft.com/en-us/azure/aks/gpu-cluster?tabs=add-ubuntu-gpu-node-pool) and the [GPU Operator documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html).
:::

### Option 1: AKS-managed GPU Driver

:::warning
Please proceed with GPU operator installation only if you have set the `--gpu-driver` field to `none` as described in [prerequisites documentation](../getting-started/02-prerequisites.md#aks-managed-gpu-driver).
:::

To enable GPUDirect RDMA, the `nvidia-peermem` kernel module must be loaded on the GPU nodes. The AKS-managed GPU driver installation does not load the Nvidia peer memory kernel module automatically. To ensure that this module is loaded on all GPU nodes, run the following command:

```bash
kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nvidia-peermem-reloader
```

### Option 2: GPU Operator Deployment

:::tip
This section assumes a basic understanding of GPU Operator and its role in Kubernetes clusters. Readers unfamiliar with GPU Operator are advised to review the official [guide](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html) before proceeding. The concepts and recommended configurations presented here build on that foundation to enable GPU workload and GPUDirect RDMA in AKS.
:::

:::warning
Please proceed with GPU operator installation only if you have created the nodepool **with** the `--gpu-driver` field set to `none` as described in [prerequisites documentation](../getting-started/02-prerequisites.md#gpu-operator-managed-gpu-driver).
:::

GPU Operator is deployed using [Helm](https://helm.sh/), and the [default Helm values](https://github.com/NVIDIA/gpu-operator/blob/v25.3.0/deployments/gpu-operator/values.yaml) are customized to align with the Network Operator and AKS requirements. Key adjustments to the Helm values disable redundant components such as NFD and enable RDMA support.

GPU operator deploys pods that require privileged access to the host system. To ensure proper operation, the `gpu-operator` namespace must be labeled with `pod-security.kubernetes.io/enforce=privileged`.

```bash
kubectl create ns gpu-operator
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
```

Save the following YAML configuration to a file named `values.yaml`:

```yaml reference
https://github.com/Azure/aks-rdma-infiniband/blob/main/configs/values/gpu-operator/values.yaml
```

Deploy GPU Operator with the following command:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm upgrade --install \
  --create-namespace -n gpu-operator \
  gpu-operator nvidia/gpu-operator \
  -f values.yaml \
  --version v25.3.0
```

## Usage of GPUDirect RDMA

Once GPU Operator and its operands are installed, configure pods to claim both GPUs and InfiniBand resources created from one of the [device plugins managed via Network Operator](network-operator#nicclusterpolicy).

### 1. SR-IOV Device Plugin

Here is an example for a GPUDirect RDMA workload using [SR-IOV Device Plugin](network-operator#1-sr-iov-device-plugin):

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
    securityContext:
      capabilities:
        # A pod without this will have a low locked memory value `# ulimit
        # -l` value of "64", this changes the value to "unlimited".
        add: ["IPC_LOCK"]
    resources:
      requests:
        nvidia.com/gpu: 8 # Claims all GPUs on the node
        rdma/ib: 8        # Claims 8 NIC; adjust to match node’s NIC count
      limits:
        nvidia.com/gpu: 8
        rdma/ib: 8
```

### 2. RDMA Shared Device Plugin

Here is an example for a GPUDirect RDMA workload using [RDMA Shared Device Plugin](network-operator#2-rdma-shared-device-plugin):

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
    securityContext:
      capabilities:
        # A pod without this will have a low locked memory value `# ulimit
        # -l` value of "64", this changes the value to "unlimited".
        add: ["IPC_LOCK"]
    resources:
      requests:
        nvidia.com/gpu: 8 # Claims all GPUs on the node
        rdma/shared_ib: 1 # Claims 1 of 63 pod slots; all NICs accessible
      limits:
        nvidia.com/gpu: 8
        rdma/shared_ib: 1
```

### 3. IP over InfiniBand (IPoIB)

Here is an example for a GPUDirect RDMA workload using [IPoIB](network-operator#3-ip-over-infiniband-ipoib):

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
    resources:
      requests:
        nvidia.com/gpu: 8 # Claims all GPUs on the node
      limits:
        nvidia.com/gpu: 8
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
