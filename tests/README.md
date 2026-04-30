# Testing RDMA Infiniband on AKS

## Deploying the Infrastructure

> [!NOTE]
> To enable debug mode, run `export DEBUG="true"` before running any script.

Make necessary changes to the following variables:

```bash
export AZURE_RESOURCE_GROUP="rdma-test"
export AZURE_REGION="southcentralus"
export NODE_POOL_VM_SIZE="Standard_ND96asr_v4"
```

Install AKS, kube-prometheus, MPI Operator, the GPU nodepool and finally the network operator:

```bash
./tests/setup-infra/deploy-aks.sh all
```

### Install GPU Operator

Install the GPU operator, only if your nodes are GPU enabled, by running the following command:

```bash
./tests/setup-infra/deploy-aks.sh install-gpu-operator
```

### AMD GPU Nodes (MI300X)

For AMD GPU node pools (e.g. `Standard_ND96isr_MI300X_v5`), NVIDIA GPU Operator is replaced with the ROCm AMD GPU Operator and an out-of-tree `amdgpu` driver installer.

Provision everything end-to-end:

```bash
export AZURE_RESOURCE_GROUP="rccl-test"
export AZURE_REGION="francecentral"
export NODE_POOL_VM_SIZE="Standard_ND96isr_MI300X_v5"
./tests/setup-infra/deploy-aks.sh all-amd
```

Or run the individual steps:

```bash
./tests/setup-infra/deploy-aks.sh install-amdgpu-driver      # loads amdgpu kernel module
./tests/setup-infra/deploy-aks.sh install-cert-manager       # AMD GPU Operator dependency
./tests/setup-infra/deploy-aks.sh install-amd-gpu-operator   # KMM + NFD + device plugin (namespace: kube-amd-gpu)
```

Once the device plugin DaemonSet is Ready, `amd.com/gpu` allocatable shows up on the AMD nodes.

Run the RCCL `all_reduce_perf` MPI job through `test.sh` (picks up the AMD allocatable via `find_amd_gpu_per_node`):

```bash
./tests/scenarios/test.sh root-nic-policy-gpu rccl
./tests/scenarios/test.sh sriov-nic-policy-gpu rccl
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu rccl
./tests/scenarios/test.sh ipoib-nic-policy-gpu rccl
```

Alternatively apply the standalone manifest directly:

```bash
kubectl apply -f tests/scenarios/k8s/rccl/mpi-job.yaml
launcher=$(kubectl get pods -l training.kubeflow.org/job-name=rccl-test,training.kubeflow.org/job-role=launcher -o jsonpath='{.items[0].metadata.name}')
kubectl logs -f "${launcher}"
```

The worker pods request `amd.com/gpu: 8` per node and run `all_reduce_perf` from [ROCm/rccl-tests](https://github.com/ROCm/rccl-tests). The container image is `ghcr.io/azure/aks-rdma-infiniband/rccl-tests:latest` ([Dockerfile](containers/rccl-tests/Dockerfile)).

## Testing

To find out all the available testing options run the following command:

```bash
./tests/scenarios/test.sh help
```

The format of the testing command is as follows:

```bash
./tests/scenarios/test.sh <IB setup scenario> <test type>
```

Here is the list of available Infiniband setup scenarios:

| Scenario Name                 | Description                                             |
|-------------------------------|---------------------------------------------------------|
| sriov-nic-policy-gpu          | Run a test with SR-IOV shared device plugin             |
| rdma-shared-device-plugin-gpu | Run a test with RDMA shared device plugin               |
| ipoib-nic-policy-gpu          | Run a test with IP over IB                              |
| root-nic-policy-gpu           | Run a test with no shared device plugin                 |
| sriov-nic-policy              | Run a test with SR-IOV shared device plugin without GPU |
| rdma-shared-device-plugin     | Run a test with RDMA shared device plugin wihtout GPU   |
| ipoib-nic-policy              | Run a test with IP over IB without GPU                  |
| root-nic-policy               | Run a test with no shared device plugin without GPU     |

Here are the available test types:

| Test Type                | Description                                                   |
|--------------------------|---------------------------------------------------------------|
| mpijob                   | Run MPI job to see the total speed (NCCL on NVIDIA GPUs)      |
| rccl                     | Run RCCL `all_reduce_perf` MPI job on AMD GPUs                |
| rdma-test                | Run RDMA tests with IB utility                                |
| nccl-test-gpudirect-rdma | Run Python based NCCL test to verify GPUDirect RDMA           |
| nccl-test-vllm-rdma      | Run Python based NCCL tests with vLLM                         |
| sockperf                 | Run tests with sockperf utility                               |
| all                      | Run all tests in the order sockperf, rdma-test and nccl-tests |
| debug                    | The tests sleep infinitely for debugging                      |

### With GPU

Run all the GPU based tests:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu all
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu all
./tests/scenarios/test.sh ipoib-nic-policy-gpu all
```

### Without GPU

Run all the non-GPU tests:

```bash
./tests/scenarios/test.sh sriov-nic-policy all
./tests/scenarios/test.sh rdma-shared-device-plugin all
./tests/scenarios/test.sh ipoib-nic-policy all
```

In [this document](expected-output.md), you can find the details of each test and what are the ideals results to expect from it.

## FAQ

### How do I save the voluminous logs?

If you want to save the logs output at the end of each run, you can pipe the output to a file, for example:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu all > sriov-nic-policy-gpu-all.log 2>&1
```

### How do I run the tests in verbose mode?

If you want to run the tests in verbose mode, you can uncomment the comments in the [`values.yaml`](scenarios/k8s/values.yaml) file:

```yaml
ncclEnvVars:
  NCCL_DEBUG: INFO             # Valid values: VERSION, WARN, INFO, TRACE
  NCCL_DEBUG_SUBSYS: INIT,NET
  DEBUG: true                  # Enable script in verbose mode.

```

- `NCCL_DEBUG` controls the verbosity of the NCCL library. This is useful for debugging the NCCL library itself. Valid values are `VERSION`, `WARN`, `INFO`, and `TRACE`.
- `NCCL_DEBUG_SUBSYS` controls the verbosity of the NCCL library for specific subsystems. For example, `INIT` and `NET` are two subsystems that can be enabled for debugging.
- `DEBUG` enables the bash scripts to run with `set -x` so as to print each command before executing it. This is useful for debugging the scripts.

### I can't run mpijob tests, because I get an error: `no matches for kind "MPIJob" in version "kubeflow.org/v2beta1"`, what do I do?

This error indicates that the MPI operator is not installed in your cluster. To install the MPI operator, run the following command:

```bash
./tests/setup-infra/deploy-aks.sh install-mpi-operator
```

Once done, you can uninstall it by running the following command:

```bash
./tests/setup-infra/deploy-aks.sh uninstall-mpi-operator
```
