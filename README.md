# AKS RDMA/Infiniband Support
To support running HPC workloads using RDMA/Infiniband on AKS, this repo provides a daemonset to install the necessary drivers and device plugins to enable RDMA on IB capable nodes. 


## Usage
There are two common use cases which are supported:
1. Networking between pods on the same node
    - Shared HCA mode: If you require connectivity between multiple pods on the same node, use shared HCA mode to enable IB communication between pods. 
2. MPI workloads on nodes with a single pod
    - SRIOV mode: If you want to give full hardware resources to one pod for maximal performance, used SRIOV to assign the VF to a single pod. 

## Prerequisites
This installation assumes you have the following setup:
- Azure resource group and cluster
- A nodepool with RDMA-capable skus:
    - For SRIOV mode, ensure vms are SRIOV-enabled
    - Refer to the HPC docs: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-hpc

## Quickstart
1. Deploy manifests:
    - SRIOV mode: `kubectl apply -k sriov-images/.`
    - Shared HCA mode: `kubectl apply -f shared-hca-images/.`
2. Check pod installation logs to confirm completion of driver installation
3. Deploy MPI workload (refer to example test pods)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
