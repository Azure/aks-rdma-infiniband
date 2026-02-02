FROM nvidia/cuda:12.8.1-devel-ubuntu24.04 as base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
    apt-get -qq install -y \
    --allow-change-held-packages \
    --no-install-recommends \
    --allow-downgrades \
    build-essential \
    libtool \
    autoconf \
    automake \
    autotools-dev \
    unzip \
    ca-certificates \
    wget \
    curl \
    openssh-server \
    vim \
    environment-modules \
    iputils-ping \
    net-tools \
    libnuma1 \
    libsubunit0 \
    libpci-dev \
    libpmix-dev \
    datacenter-gpu-manager \
    g++ \
    libopenmpi-dev \
    openmpi-bin \
    git \
    ibverbs-utils \
    libibverbs-dev \
    libibumad3 \
    libibumad-dev \
    librdmacm-dev \
    rdmacm-utils \
    infiniband-diags \
    ibverbs-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# NCCL Tests: https://github.com/NVIDIA/nccl-tests
# This commit corresponds to the release v2.17.6
# Works with NCCL 2.25.1+cuda12.8 (included in the CUDA 12.8.1 base image)
ENV NCCL_TESTS_COMMIT_SHA=da0b547
# Support for Hopper (H100/H200) - compute_90 and Blackwell (GB200/GB300) - compute_100
ENV CUDA12_GENCODE='-gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_100,code=sm_100'
ENV CUDA12_PTX='-gencode=arch=compute_90,code=compute_90 -gencode=arch=compute_100,code=compute_100'
WORKDIR /opt/nccl-tests
RUN wget -q -O - https://github.com/NVIDIA/nccl-tests/archive/${NCCL_TESTS_COMMIT_SHA}.tar.gz | tar --strip-components=1 -xzf - && \
    mpicc -show && \
    export CXX=mpic++ && \
    make -j20 MPI=1 MPI_HOME=/usr/include/openmpi NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" && \
    ln -s /opt/nccl-tests /opt/nccl_tests

RUN ldconfig

# SSH dependencies for MPI
RUN sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
    sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config && \
    sed -i "s/[ #]\(.*Port \).*/ \12222/g" /etc/ssh/ssh_config && \
    sed -i "s/#\(Port \).*/\12222/g" /etc/ssh/sshd_config && \
    mkdir /var/run/sshd -p
