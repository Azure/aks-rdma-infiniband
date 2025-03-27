# Testing RDMA Infiniband on AKS

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
./tests/setup-infra/deploy-aks.sh deploy-aks
./tests/setup-infra/deploy-aks.sh add-nodepool
./tests/setup-infra/deploy-aks.sh install-network-operator
```

If the nodes support GPU, then install the GPU operator:

```bash
./tests/setup-infra/deploy-aks.sh install-gpu-operator
```

Run the GPU based tests:

```bash
./tests/scenarios/test.sh root-nic-policy-gpu
./tests/scenarios/test.sh sriov-nic-policy-gpu
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu
```

Run the non-GPU tests:

```bash
./tests/scenarios/test.sh root-nic-policy
./tests/scenarios/test.sh sriov-nic-policy
./tests/scenarios/test.sh rdma-shared-device-plugin
```
