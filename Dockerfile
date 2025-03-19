# Base image from https://github.com/Azure/AzureML-Containers with CUDA 12.4 matching GPU Operator v24.9.2
FROM mcr.microsoft.com/azureml/openmpi5.0-cuda12.4-ubuntu22.04@sha256:2f37cf15789e10ddbbff6e5431dab0c7a789cccc427ef78c22be06e929458f76

LABEL org.opencontainers.image.description="Container image for benchmarking RDMA over InfiniBand and NCCL performance on AKS"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends \
    autoconf \
    automake \
    autotools-dev \
    build-essential \
    ibverbs-utils \
    infiniband-diags \
    libibumad-dev \
    libibumad3 \
    libibverbs-dev \
    libpci-dev \
    librdmacm-dev \
    libtool \
    rdmacm-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build
WORKDIR /tmp/build

# Install perftest binaries for measuring InfiniBand performance
# https://github.com/linux-rdma/perftest/releases/tag/25.01.0-0.80
ARG PERFTEST_TAG="25.01.0-0.80"
RUN git clone -b ${PERFTEST_TAG} --depth 1 https://github.com/linux-rdma/perftest && \
    cd perftest && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make && \
    make install

# Install nccl-tests binaries for mea
# https://github.com/NVIDIA/nccl-tests/releases/tag/v2.14.1
ARG NCCL_TESTS_TAG="v2.14.1"
RUN git clone -b ${NCCL_TESTS_TAG} --depth 1 https://github.com/NVIDIA/nccl-tests.git && \
    cd nccl-tests && \
    make \
    MPI=1 CUDA_HOME=/usr/local/cuda MPI_HOME=/usr/local/openmpi && \
    cp ./build/*_perf /usr/local/bin

RUN rm -rf /tmp/build

# Locate NCCL RDMA plugins inside this container
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/nccl-rdma-sharp-plugins/lib"

WORKDIR /
