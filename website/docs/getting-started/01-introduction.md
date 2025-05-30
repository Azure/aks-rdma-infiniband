---
title: Introduction
slug: /
---

This documentation serves as a guide for deploying high-performance computing (HPC) workloads on Azure Kubernetes Service (AKS) clusters with support for **Remote Direct Memory Access (RDMA) over InfiniBand (IB)**, and **[GPUDirect RDMA](https://developer.nvidia.com/gpudirect)**.

HPC workloads, including distributed AI model training and serving require efficient, low-latency communication between nodes. Traditional networking protocols, such as TCP/IP, often introduce performance overheads that limit scalability. RDMA over InfiniBand mitigates these constraints by enabling direct memory access between devices, bypassing CPU and kernel. When combined with NVIDIA’s GPUDirect RDMA, it facilitates direct GPU-to-GPU communication across nodes, optimizing throughput and latency for GPU-accelerated applications.

## Core Components

This guide focuses on ways of enabling RDMA over InfiniBand on AKS clusters. To enable this functionality, we recommend using Nvidia [Network Operator](https://docs.nvidia.com/networking/display/cokan10/network+operator). Furthermore, it provides guidance on configuring GPUs using AKS-managed GPU drivers or using the Nvidia [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html). To streamline deployment and ensure optimal performance, this documentation provides recommended configurations and Helm values for both operators, tailored to Azure’s high-performance infrastructure.

- 🌐 **Network Operator**: Automates the deployment and management of networking components, including Mellanox NICs and drivers, to support RDMA over Infiniband.
- 🤖 **GPU Drivers**:
  - **AKS-managed GPU drivers**: These are the default GPU drivers provided by AKS, which can be used without additional configuration.
  - **GPU Operator**: Facilitates the deployment and management of NVIDIA GPU drivers, container runtimes, and Kubernetes device plugins, ensuring that GPUs are correctly configured for pods. The official [GPU Operator documentation on AKS](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html) is a good starting point for understanding GPU Operator's role in AKS clusters.

These operators integrate with Azure’s HPC virtual machine offerings (e.g., `NDasrA100_v4`, `NDm_A100_v4`) and Mellanox ConnectX NICs to provide a solution for deploying and managing HPC workloads on AKS.

## Beyond AKS

While this guide is designed specifically for AKS, the underlying concepts, configurations, and best practices for RDMA over InfiniBand, and GPUDirect RDMA can be adapted to other Kubernetes clusters hosted on Azure. For example, clusters managed via [Cluster API for Azure (CAPZ)](https://capz.sigs.k8s.io/) can leverage these principles with appropriate modifications to account for differences in cluster provisioning and management.

## Support

This guide is an open-source project hosted at [github.com/Azure/aks-rdma-infiniband](https://github.com/Azure/aks-rdma-infiniband) and is not covered by the [Microsoft Azure Support Policy](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/linux/support-linux-open-source-technology). For assistance, please review [existing issues](https://github.com/Azure/aks-rdma-infiniband/issues) on the project repository. If your question or issue is not addressed, you are encouraged to [submit a new issue](https://github.com/Azure/aks-rdma-infiniband/issues/new). The project maintainers will respond to the best of their abilities.
