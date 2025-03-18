"use strict";(self.webpackChunkaks_rdma_infiniband=self.webpackChunkaks_rdma_infiniband||[]).push([[624],{7397:(e,n,i)=>{i.r(n),i.d(n,{assets:()=>a,contentTitle:()=>o,default:()=>h,frontMatter:()=>d,metadata:()=>r,toc:()=>l});const r=JSON.parse('{"id":"getting-started/prerequisites","title":"Prerequisites","description":"This section details the prerequisites for deploying an AKS cluster with support for high-speed InfiniBand networking and Remote Direct Memory Access (RDMA), including optional configurations for GPUDirect RDMA.","source":"@site/docs/getting-started/02-prerequisites.md","sourceDirName":"getting-started","slug":"/getting-started/prerequisites","permalink":"/aks-rdma-infiniband/getting-started/prerequisites","draft":false,"unlisted":false,"editUrl":"https://github.com/Azure/aks-rdma-infiniband/blob/main/website/docs/getting-started/02-prerequisites.md","tags":[],"version":"current","sidebarPosition":2,"frontMatter":{"title":"Prerequisites"},"sidebar":"sidebar","previous":{"title":"Introduction","permalink":"/aks-rdma-infiniband/"},"next":{"title":"Network Operator","permalink":"/aks-rdma-infiniband/configurations/network-operator"}}');var t=i(4848),s=i(8453);const d={title:"Prerequisites"},o=void 0,a={},l=[{value:"AKS Nodepools",id:"aks-nodepools",level:2},{value:"Requirements",id:"requirements",level:3},{value:"Skip GPU Driver Installation",id:"skip-gpu-driver-installation",level:3},{value:"Recommendations",id:"recommendations",level:4},{value:"Appendix",id:"appendix",level:2},{value:"Understanding VM Size Naming Conventions",id:"understanding-vm-size-naming-conventions",level:3},{value:"Examples",id:"examples",level:4}];function c(e){const n={a:"a",admonition:"admonition",code:"code",h2:"h2",h3:"h3",h4:"h4",li:"li",p:"p",pre:"pre",strong:"strong",table:"table",tbody:"tbody",td:"td",th:"th",thead:"thead",tr:"tr",ul:"ul",...(0,s.R)(),...e.components};return(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(n.p,{children:"This section details the prerequisites for deploying an AKS cluster with support for high-speed InfiniBand networking and Remote Direct Memory Access (RDMA), including optional configurations for GPUDirect RDMA."}),"\n",(0,t.jsx)(n.h2,{id:"aks-nodepools",children:"AKS Nodepools"}),"\n",(0,t.jsx)(n.p,{children:"An active AKS cluster is required as the foundation for deploying RDMA over InfiniBand capabilities. The cluster serves as the Kubernetes environment where Network Operator and GPU Operator (if using GPUDirect RDMA) will be installed."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"Requirement"}),": Create an AKS cluster using the ",(0,t.jsx)(n.a,{href:"https://portal.azure.com",children:"Azure Portal"})," or ",(0,t.jsx)(n.a,{href:"https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest",children:"Azure CLI"}),". Ensure the cluster is running a supported Kubernetes version compatible with ",(0,t.jsx)(n.a,{href:"https://docs.nvidia.com/networking/display/kubernetes2501/platform-support.html",children:"Network Operator"})," and ",(0,t.jsx)(n.a,{href:"https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html",children:"GPU Operator"}),"."]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"Configuration"}),": The cluster must be deployed in a region that supports the required VM sizes with RDMA over InfiniBand capabilities."]}),"\n"]}),"\n",(0,t.jsx)(n.p,{children:"To create an AKS cluster, use the following Azure CLI command as a starting point:"}),"\n",(0,t.jsx)(n.pre,{children:(0,t.jsx)(n.code,{className:"language-bash",children:'export AZURE_RESOURCE_GROUP="myResourceGroup"\nexport CLUSTER_NAME="myAKSCluster"\nexport NODEPOOL_NAME="ibnodepool"\nexport NODEPOOL_NODE_COUNT="2"\nexport NODEPOOL_VM_SIZE="Standard_ND96asr_v4"\n\naz aks create \\\n  --resource-group "${AZURE_RESOURCE_GROUP}" \\\n  --name "${CLUSTER_NAME}" \\\n  --node-count 1 \\\n  --generate-ssh-keys\n'})}),"\n",(0,t.jsx)(n.p,{children:"Additional nodepools will be added in the next step to meet specific hardware requirements."}),"\n",(0,t.jsx)(n.h3,{id:"requirements",children:"Requirements"}),"\n",(0,t.jsx)(n.p,{children:"The AKS cluster requires a dedicated nodepool configured to support InfiniBand networking and RDMA. For AI workloads leveraging GPUDirect RDMA, GPU support is also necessary."}),"\n",(0,t.jsxs)(n.table,{children:[(0,t.jsx)(n.thead,{children:(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.th,{children:"Requirement"}),(0,t.jsx)(n.th,{children:"Recommended Configuration"}),(0,t.jsx)(n.th,{children:"Description"})]})}),(0,t.jsxs)(n.tbody,{children:[(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Minimum Nodes"})}),(0,t.jsx)(n.td,{children:"At least 2 nodes"}),(0,t.jsx)(n.td,{children:"Enables cross-node communication for RDMA over InfiniBand; more nodes for scaling"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Operating System"})}),(0,t.jsx)(n.td,{children:"Ubuntu"}),(0,t.jsx)(n.td,{children:"Well-supported by NVIDIA drivers and software stack; other OS options may be available"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Hardware"})}),(0,t.jsx)(n.td,{children:(0,t.jsx)(n.a,{href:"https://www.nvidia.com/en-us/networking/ethernet-adapters/",children:"Mellanox ConnectX NICs"})}),(0,t.jsx)(n.td,{children:"High-performance network interface cards (NICs) for RDMA over InfiniBand support"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"VM Size"})}),(0,t.jsx)(n.td,{children:(0,t.jsx)(n.a,{href:"https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nd-family",children:"ND-series"})}),(0,t.jsxs)(n.td,{children:["NVIDIA GPU-enabled VMs with InfiniBand support; e.g., ",(0,t.jsx)(n.code,{children:"Standard_ND96asr_v4"})," or ",(0,t.jsx)(n.code,{children:"Standard_ND96isr_H100_v5"})]})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"GPUDirect RDMA"})}),(0,t.jsx)(n.td,{children:"Optional; requires GPU-enabled VMs (e.g., ND-series with A100 or H100 GPUs)"}),(0,t.jsx)(n.td,{children:"Enables direct GPU-to-GPU communication; omit GPUs for non-GPUDirect RDMA use cases"})]})]})]}),"\n",(0,t.jsx)(n.p,{children:"To configure an AKS nodepool with RDMA over InfiniBand support - either without GPUs or with a GPU-enabled VM size using the AKS-managed GPU driver installation, use the following command:"}),"\n",(0,t.jsx)(n.pre,{children:(0,t.jsx)(n.code,{className:"language-bash",children:'az aks nodepool add \\\n  --resource-group "${AZURE_RESOURCE_GROUP}" \\\n  --cluster-name "${CLUSTER_NAME}" \\\n  --name "${NODEPOOL_NAME}" \\\n  --node-count "${NODEPOOL_NODE_COUNT}" \\\n  --node-vm-size "${NODEPOOL_VM_SIZE}" \\\n  --os-sku Ubuntu\n'})}),"\n",(0,t.jsxs)(n.p,{children:["To create a GPU nodepool ",(0,t.jsx)(n.strong,{children:"without"})," GPU Driver installation, use the following command (see below section for more details):"]}),"\n",(0,t.jsx)(n.pre,{children:(0,t.jsx)(n.code,{className:"language-bash",children:'az aks nodepool add \\\n  --resource-group "${AZURE_RESOURCE_GROUP}" \\\n  --cluster-name "${CLUSTER_NAME}" \\\n  --name "${NODEPOOL_NAME}" \\\n  --node-count "${NODEPOOL_NODE_COUNT}" \\\n  --node-vm-size "${NODEPOOL_VM_SIZE}" \\\n  --os-sku Ubuntu \\\n  # highlight-next-line\n  --skip-gpu-driver-install\n'})}),"\n",(0,t.jsx)(n.h3,{id:"skip-gpu-driver-installation",children:"Skip GPU Driver Installation"}),"\n",(0,t.jsx)(n.admonition,{type:"info",children:(0,t.jsxs)(n.p,{children:["Read more about the GPU driver installation options in AKS and the NVIDIA GPU Operator in the ",(0,t.jsx)(n.a,{href:"https://learn.microsoft.com/en-us/azure/aks/gpu-cluster?tabs=add-ubuntu-gpu-node-pool",children:"AKS documentation"})," and the ",(0,t.jsx)(n.a,{href:"https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/microsoft-aks.html",children:"GPU Operator documentation"}),"."]})}),"\n",(0,t.jsx)(n.p,{children:"When provisioning GPU nodepools in an AKS cluster, the cluster administrator has the option to either rely on the default GPU driver installation managed by AKS or via GPU Operator. This decision impacts cluster setup, maintenance, and compatibility."}),"\n",(0,t.jsxs)(n.table,{children:[(0,t.jsx)(n.thead,{children:(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.th,{}),(0,t.jsx)(n.th,{children:(0,t.jsx)(n.strong,{children:"Without NVIDIA GPU Operator (Default)"})}),(0,t.jsx)(n.th,{children:(0,t.jsx)(n.strong,{children:"With NVIDIA GPU Operator (Skip GPU Driver)"})})]})}),(0,t.jsxs)(n.tbody,{children:[(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Automation"})}),(0,t.jsx)(n.td,{children:"AKS-managed drivers; no automation for other components"}),(0,t.jsx)(n.td,{children:"Automates driver, device plugins, and container runtimes via GPU Operator"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Complexity"})}),(0,t.jsx)(n.td,{children:"Default: Minimal setup, no flexibility; Manual: High setup effort"}),(0,t.jsx)(n.td,{children:"Moderate setup (deploy operator); simplified ongoing management"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Support"})}),(0,t.jsx)(n.td,{children:"Fully supported by AKS; no preview features"}),(0,t.jsxs)(n.td,{children:[(0,t.jsx)(n.code,{children:"--skip-gpu-driver-install"})," is a preview feature; limited support available"]})]})]})]}),"\n",(0,t.jsx)(n.h4,{id:"recommendations",children:"Recommendations"}),"\n",(0,t.jsxs)(n.p,{children:["For GPUDirect RDMA over InfiniBand, use the NVIDIA GPU Operator with ",(0,t.jsx)(n.code,{children:"--skip-gpu-driver-install"})," when creating the nodepool to leverage GPU Operator's automation and management capabilities. This approach simplifies the deployment of GPU drivers, device plugins, and container runtimes, ensuring compatibility with the latest NVIDIA stack."]}),"\n",(0,t.jsx)(n.p,{children:"Opt for AKS-managed driver for simpler GPU tasks without GPUDirect RDMA needs."}),"\n",(0,t.jsx)(n.h2,{id:"appendix",children:"Appendix"}),"\n",(0,t.jsx)(n.h3,{id:"understanding-vm-size-naming-conventions",children:"Understanding VM Size Naming Conventions"}),"\n",(0,t.jsx)(n.p,{children:"Azure VM sizes use a naming convention to indicate their hardware capabilities. The table below explains the components of VM sizes relevant to RDMA over InfiniBand, and GPUDirect RDMA support in AKS, with examples from the ND-series."}),"\n",(0,t.jsxs)(n.table,{children:[(0,t.jsx)(n.thead,{children:(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.th,{children:"Component"}),(0,t.jsx)(n.th,{children:"Meaning"})]})}),(0,t.jsxs)(n.tbody,{children:[(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"N"})}),(0,t.jsx)(n.td,{children:"NVIDIA GPU-enabled"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"D"})}),(0,t.jsx)(n.td,{children:"Training and inference capable"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"r"})}),(0,t.jsx)(n.td,{children:"RDMA capable"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"a"})}),(0,t.jsx)(n.td,{children:"AMD CPUs"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"s"})}),(0,t.jsx)(n.td,{children:"Premium storage capable"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"vX"})}),(0,t.jsx)(n.td,{children:"Version/generation (e.g., v4, v5)"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"Number"})}),(0,t.jsx)(n.td,{children:"vCPUs (e.g., 96)"})]}),(0,t.jsxs)(n.tr,{children:[(0,t.jsx)(n.td,{children:(0,t.jsx)(n.strong,{children:"GPU"})}),(0,t.jsx)(n.td,{children:"Specific GPU model (e.g., H100)"})]})]})]}),"\n",(0,t.jsx)(n.h4,{id:"examples",children:"Examples"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.code,{children:"Standard_ND96asr_v4"}),": NVIDIA GPUs (N), Training and inference (D), AMD CPUs (a), premium storage (s), RDMA (r), A100 GPUs, 96 vCPUs, version 4 (v4)."]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.code,{children:"Standard_ND96isr_H100_v5"}),": NVIDIA GPUs (N), Training and inference (D), RDMA (r), premium storage (s), H100 GPUs, 96 vCPUs, version 5 (v5)."]}),"\n"]})]})}function h(e={}){const{wrapper:n}={...(0,s.R)(),...e.components};return n?(0,t.jsx)(n,{...e,children:(0,t.jsx)(c,{...e})}):c(e)}},8453:(e,n,i)=>{i.d(n,{R:()=>d,x:()=>o});var r=i(6540);const t={},s=r.createContext(t);function d(e){const n=r.useContext(s);return r.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function o(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(t):e.components||t:d(e.components),r.createElement(s.Provider,{value:n},e.children)}}}]);