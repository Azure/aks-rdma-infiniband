ARG CUDA_VERSION_MINOR=12.8.1
ARG BASE_IMAGE=nvidia/cuda:${CUDA_VERSION_MINOR}-devel-ubuntu24.04
FROM ${BASE_IMAGE} as base

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
# This commit corresponds to the release v2.14.1
ENV NCCL_TESTS_COMMIT_SHA=b4300cc
ENV CUDA12_GENCODE='-gencode=arch=compute_90,code=sm_90'
ENV CUDA12_PTX='-gencode=arch=compute_90,code=compute_90'
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
