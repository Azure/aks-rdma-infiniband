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

### With GPU

Run the GPU based tests:

```bash
./tests/scenarios/test.sh root-nic-policy-gpu
./tests/scenarios/test.sh sriov-nic-policy-gpu
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu
./tests/scenarios/test.sh ipoib-nic-policy-gpu
```

### Without GPU

Run the non-GPU tests:

```bash
./tests/scenarios/test.sh root-nic-policy
./tests/scenarios/test.sh sriov-nic-policy
./tests/scenarios/test.sh rdma-shared-device-plugin
./tests/scenarios/test.sh ipoib-nic-policy
```

## FAQ

### How do I save the voluminous logs?

If you want to save the logs output at the end of each run, you can pipe the output to a file, for example:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu > sriov-nic-policy-gpu.log 2>&1
```

### How do I run the tests in verbose mode?

If you want to run the tests in verbose mode, you can uncomment the comments in the [`kustomization.yaml`](scenarios/k8s/base/kustomization.yaml) file:

```yaml
  - NCCL_DEBUG=INFO             # Valid values: VERSION, WARN, INFO, TRACE
  - NCCL_DEBUG_SUBSYS=INIT,NET
  - DEBUG=true                  # Enable script in verbose mode.
```

- `NCCL_DEBUG` controls the verbosity of the NCCL library. This is useful for debugging the NCCL library itself. Valid values are `VERSION`, `WARN`, `INFO`, and `TRACE`.
- `NCCL_DEBUG_SUBSYS` controls the verbosity of the NCCL library for specific subsystems. For example, `INIT` and `NET` are two subsystems that can be enabled for debugging.
- `DEBUG` enables the bash scripts to run with `set -x` so as to print each command before executing it. This is useful for debugging the scripts.
