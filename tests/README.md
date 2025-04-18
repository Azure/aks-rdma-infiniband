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

Install AKS, the nodepool and the network operator:

```bash
./tests/setup-infra/deploy-aks.sh all
```

### Optional: Install GPU Operator

Install the GPU operator, only if your nodes are GPU enabled, by running the following command:

```bash
./tests/setup-infra/deploy-aks.sh install-gpu-operator
```

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
| root-nic-policy-gpu           | Run a test with no shared device plugin                 |
| sriov-nic-policy-gpu          | Run a test with SR-IOV shared device plugin             |
| rdma-shared-device-plugin-gpu | Run a test with RDMA shared device plugin               |
| ipoib-nic-policy-gpu          | Run a test with IP over IB                              |
| root-nic-policy               | Run a test with no shared device plugin without GPU     |
| sriov-nic-policy              | Run a test with SR-IOV shared device plugin without GPU |
| rdma-shared-device-plugin     | Run a test with RDMA shared device plugin wihtout GPU   |
| ipoib-nic-policy              | Run a test with IP over IB without GPU                  |

Here are the available test types:

| Test Type                | Description                                                   |
|--------------------------|---------------------------------------------------------------|
| sockperf                 | Run tests with sockperf utility                               |
| rdma-test                | Run RDMA tests with IB utility                                |
| nccl-test-vllm-rdma      | Run Python based NCCL tests with vLLM                         |
| nccl-test-gpudirect-rdma | Run Python based NCCL test to verify GPUDirect RDMA           |
| mpijob                   | Run MPI job to see the total speed                            |
| debug                    | The tests sleep infinitely for debugging                      |
| all                      | Run all tests in the order sockperf, rdma-test and nccl-tests |

### With GPU

Run all the GPU based tests:

```bash
./tests/scenarios/test.sh root-nic-policy-gpu all
./tests/scenarios/test.sh sriov-nic-policy-gpu all
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu all
./tests/scenarios/test.sh ipoib-nic-policy-gpu all
```

### Without GPU

Run all the non-GPU tests:

```bash
./tests/scenarios/test.sh root-nic-policy all
./tests/scenarios/test.sh sriov-nic-policy all
./tests/scenarios/test.sh rdma-shared-device-plugin all
./tests/scenarios/test.sh ipoib-nic-policy all
```

## FAQ

### How do I save the voluminous logs?

If you want to save the logs output at the end of each run, you can pipe the output to a file, for example:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu > sriov-nic-policy-gpu.log 2>&1
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
