"use strict";(self.webpackChunkaks_rdma_infiniband=self.webpackChunkaks_rdma_infiniband||[]).push([[249],{8041:(e,n,i)=>{i.r(n),i.d(n,{assets:()=>d,contentTitle:()=>a,default:()=>h,frontMatter:()=>t,metadata:()=>r,toc:()=>l});const r=JSON.parse('{"id":"configurations/network-operator","title":"Network Operator","description":"This guide details recommended configurations for Network Operator v25.1.0 to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs.","source":"@site/docs/configurations/01-network-operator.md","sourceDirName":"configurations","slug":"/configurations/network-operator","permalink":"/aks-rdma-infiniband/configurations/network-operator","draft":false,"unlisted":false,"editUrl":"https://github.com/Azure/aks-rdma-infiniband/blob/main/website/docs/configurations/01-network-operator.md","tags":[],"version":"current","sidebarPosition":1,"frontMatter":{"title":"Network Operator"},"sidebar":"sidebar","previous":{"title":"Prerequisites","permalink":"/aks-rdma-infiniband/getting-started/prerequisites"},"next":{"title":"GPU Operator","permalink":"/aks-rdma-infiniband/configurations/gpu-operator"}}');var s=i(4848),o=i(8453);const t={title:"Network Operator"},a=void 0,d={},l=[{value:"Recommended Configuration",id:"recommended-configuration",level:2},{value:"Helm Values",id:"helm-values",level:3},{value:"NicClusterPolicy",id:"nicclusterpolicy",level:3},{value:"SR-IOV Device Plugin",id:"sr-iov-device-plugin",level:4},{value:"RDMA Shared Device Plugin",id:"rdma-shared-device-plugin",level:4},{value:"Recommendations",id:"recommendations",level:4},{value:"Order of Operations",id:"order-of-operations",level:2},{value:"Frequently Asked Questions",id:"frequently-asked-questions",level:2},{value:"Why is secondary IP address assignment not required for RDMA over InfiniBand in AKS?",id:"why-is-secondary-ip-address-assignment-not-required-for-rdma-over-infiniband-in-aks",level:3}];function c(e){const n={a:"a",admonition:"admonition",code:"code",h2:"h2",h3:"h3",h4:"h4",li:"li",ol:"ol",p:"p",pre:"pre",strong:"strong",ul:"ul",...(0,o.R)(),...e.components};return(0,s.jsxs)(s.Fragment,{children:[(0,s.jsx)(n.p,{children:"This guide details recommended configurations for Network Operator v25.1.0 to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs."}),"\n",(0,s.jsx)(n.admonition,{type:"tip",children:(0,s.jsxs)(n.p,{children:["This guide assumes a basic understanding of Network Operator and its role in Kubernetes clusters. Readers unfamiliar with the Network Operator are advised to review the official ",(0,s.jsx)(n.a,{href:"https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html",children:"Getting Started Guide"})," before proceeding. The concepts and recommended configurations presented here build on that foundation to enable RDMA over InfiniBand in AKS. This documentation is based on Network Operator v25.1.0."]})}),"\n",(0,s.jsx)(n.h2,{id:"recommended-configuration",children:"Recommended Configuration"}),"\n",(0,s.jsx)(n.p,{children:"This guide details recommended configurations for Network Operator v25.1.0 to enable RDMA over InfiniBand, optimized for AKS environments with Mellanox NICs."}),"\n",(0,s.jsx)(n.h3,{id:"helm-values",children:"Helm Values"}),"\n",(0,s.jsxs)(n.p,{children:["Network Operator is deployed using ",(0,s.jsx)(n.a,{href:"https://helm.sh/",children:"Helm"}),", and the ",(0,s.jsx)(n.a,{href:"https://github.com/Mellanox/network-operator/blob/v25.1.0/deployment/network-operator/values.yaml",children:"default Helm values"})," are recommended unless specific customizations are required. These defaults include ",(0,s.jsx)(n.a,{href:"https://kubernetes-sigs.github.io/node-feature-discovery/stable/get-started/index.html",children:"Node Feature Discovery (NFD)"}),", a critical dependency that labels nodes with hardware details (e.g., Mellanox NIC presence) for pod scheduling."]}),"\n",(0,s.jsxs)(n.p,{children:["Save the following YAML configuration to a file named ",(0,s.jsx)(n.code,{children:"values.yaml"}),":"]}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-yaml",metastring:"reference",children:"https://github.com/Azure/aks-rdma-infiniband/blob/main/configs/values/network-operator/values.yaml\n"})}),"\n",(0,s.jsx)(n.p,{children:"Deploy Network Operator with the following commands:"}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-bash",children:"helm repo add nvidia https://helm.ngc.nvidia.com/nvidia\nhelm repo update\n\nhelm upgrade --install \\\n  --create-namespace -n network-operator \\\n  network-operator nvidia/network-operator \\\n  -f values.yaml \\\n  --version v25.1.0\n"})}),"\n",(0,s.jsx)(n.h3,{id:"nicclusterpolicy",children:"NicClusterPolicy"}),"\n",(0,s.jsxs)(n.p,{children:["Post-installation, create a ",(0,s.jsx)(n.code,{children:"NicClusterPolicy"})," Custom Resource (CR) to define the desired state of networking components, such as Mellanox driver version and which device plugins to deploy. Two configurations are provided below: SR-IOV Device Plugin for exclusive Network Interface Card (NIC) access and RDMA Shared Device Plugin for shared access."]}),"\n",(0,s.jsx)(n.h4,{id:"sr-iov-device-plugin",children:"SR-IOV Device Plugin"}),"\n",(0,s.jsxs)(n.p,{children:["The SR-IOV Device Plugin assigns each InfiniBand-enabled NIC (e.g., Mellanox ConnectX-6) to a single pod as a Kubernetes resource (",(0,s.jsx)(n.code,{children:"rdma/ib"}),"). The number of available resources matches the count of physical NICs on the node (e.g., 1 NIC = 1 resource), ideal for workloads requiring maximum performance and isolation."]}),"\n",(0,s.jsxs)(n.p,{children:["To deploy the above config, create a ",(0,s.jsx)(n.code,{children:"NicClusterPolicy"})," CR with the following YAML:"]}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-bash",children:"kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/sriov-device-plugin\n"})}),"\n",(0,s.jsx)(n.p,{children:"Example pod configuration:"}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-yaml",children:"---\napiVersion: v1\nkind: Pod\nmetadata:\n  name: ib-pod\nspec:\n  containers:\n  - name: ib\n    image: images.my-company.example/app:v4\n    resources:\n      requests:\n        rdma/ib: 8 # Claims 8 NIC; adjust to match node\u2019s NIC count\n      limits:\n        rdma/ib: 8\n"})}),"\n",(0,s.jsx)(n.h4,{id:"rdma-shared-device-plugin",children:"RDMA Shared Device Plugin"}),"\n",(0,s.jsxs)(n.p,{children:["The RDMA Shared Device Plugin enables multiple pods to share all InfiniBand NICs on a node, exposed as ",(0,s.jsx)(n.code,{children:"rdma/shared_ib"}),". The resource count represents the maximum number of concurrent pods (default: 63 per node, configurable), not the NICs themselves, suiting resource-efficient workloads."]}),"\n",(0,s.jsxs)(n.p,{children:["To deploy the above config, create a ",(0,s.jsx)(n.code,{children:"NicClusterPolicy"})," CR with the following YAML:"]}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-bash",children:"kubectl apply -k https://github.com/Azure/aks-rdma-infiniband/configs/nicclusterpolicy/rdma-shared-device-plugin\n"})}),"\n",(0,s.jsx)(n.p,{children:"Example pod configuration:"}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-yaml",children:"---\napiVersion: v1\nkind: Pod\nmetadata:\n  name: ib-pod\nspec:\n  containers:\n  - name: ib\n    image: images.my-company.example/app:v4\n    resources:\n      requests:\n        rdma/shared_ib: 1 # Claims 1 of 63 pod slots; all NICs accessible\n      limits:\n        rdma/shared_ib: 1\n"})}),"\n",(0,s.jsx)(n.h4,{id:"recommendations",children:"Recommendations"}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Maximum Performance"}),": Use the SR-IOV Device Plugin with one pod per node claiming all InfiniBand NICs (e.g., ",(0,s.jsx)(n.code,{children:"rdma/ib: <NIC count>"}),"), ensuring exclusive RDMA access for optimal throughput and isolation."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Resource Efficiency"}),": Use the RDMA Shared Device Plugin for multi-pod sharing. For GPUDirect RDMA workloads, note that if a pod claims ",(0,s.jsx)(n.code,{children:"rdma/shared_ib: 1"})," and all GPUs (e.g., 8 on ",(0,s.jsx)(n.code,{children:"Standard_ND96asr_v4"}),"), no additional pods of the same type can schedule on that node due to GPU exhaustion, despite remaining RDMA slots."]}),"\n"]}),"\n",(0,s.jsx)(n.h2,{id:"order-of-operations",children:"Order of Operations"}),"\n",(0,s.jsx)(n.p,{children:"The installation process follows this sequence:"}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Network Operator Deployment"}),": The Helm chart installs the Network Operator, including its controller manager deployment to manage ",(0,s.jsx)(n.code,{children:"NicClusterPolicy"})," reconciliation."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Node Feature Discovery (NFD)"}),": Deployed as part of Network Operator Helm chart, NFD labels nodes with hardware details (e.g., Mellanox NICs) for certain pods to select nodes with specific hardware features."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsxs)(n.strong,{children:[(0,s.jsx)(n.code,{children:"NicClusterPolicy"})," Reconciliation"]}),": Creates DaemonSets based on the CR:","\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.code,{children:"mofed-ubuntu22.04-ds"}),": Installs kernel drivers (e.g., Mellanox OFED and InfiniBand drivers) to enable RDMA over InfiniBand capabilities on the nodes."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.code,{children:"device-plugin"}),": Installs the SR-IOV Device Plugin and/or RDMA Shared Device Plugin, depending on the selected configuration. This plugin exposes the NICs as claimable resources in Kubernetes using the ",(0,s.jsx)(n.a,{href:"https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/",children:"Device Plugin"})," framework."]}),"\n"]}),"\n"]}),"\n"]}),"\n",(0,s.jsx)(n.h2,{id:"frequently-asked-questions",children:"Frequently Asked Questions"}),"\n",(0,s.jsx)(n.h3,{id:"why-is-secondary-ip-address-assignment-not-required-for-rdma-over-infiniband-in-aks",children:"Why is secondary IP address assignment not required for RDMA over InfiniBand in AKS?"}),"\n",(0,s.jsxs)(n.p,{children:["RDMA over InfiniBand operates below the TCP/IP stack, relying on direct memory access rather than IP-based networking. Tools like ",(0,s.jsx)(n.a,{href:"https://github.com/k8snetworkplumbingwg/multus-cni",children:"Multus"})," and ",(0,s.jsx)(n.a,{href:"https://github.com/k8snetworkplumbingwg/whereabouts",children:"whereabouts"})," for secondary network attachment and IPAM are not strictly required for RDMA over InfiniBand in AKS, as Device Plugins directly expose InfiniBand resources to pods."]}),"\n",(0,s.jsxs)(n.p,{children:["If you wish to operate in the TCP/IP stack over the InfiniBand network, refer to the ",(0,s.jsx)(n.a,{href:"https://docs.nvidia.com/networking/display/kubernetes2501/getting-started-kubernetes.html",children:"NVIDIA Getting Started Guide for Kubernetes"})," for detailed instructions."]})]})}function h(e={}){const{wrapper:n}={...(0,o.R)(),...e.components};return n?(0,s.jsx)(n,{...e,children:(0,s.jsx)(c,{...e})}):c(e)}},8453:(e,n,i)=>{i.d(n,{R:()=>t,x:()=>a});var r=i(6540);const s={},o=r.createContext(s);function t(e){const n=r.useContext(o);return r.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function a(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(s):e.components||s:t(e.components),r.createElement(o.Provider,{value:n},e.children)}}}]);