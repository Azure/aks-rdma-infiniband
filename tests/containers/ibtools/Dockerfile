# vllm image is also based on ubuntu:22.04
FROM ubuntu:22.04 AS build-stage

WORKDIR /nvidia-tools

RUN apt update && apt install -y \
    curl \
    unzip \
    perl \
    make \
    automake \
    autoconf \
    m4 \
    libtool-bin \
    g++ \
    pkg-config \
    libibverbs-dev \
    librdmacm-dev \
    libssl-dev

# Build sockperf
RUN curl -LO https://github.com/Mellanox/sockperf/archive/refs/heads/sockperf_v2.zip && \
    unzip sockperf_v2.zip && \
    cd sockperf-sockperf_v2 && \
    ./autogen.sh && ./configure && make && make install && \
    cd -

FROM vllm/vllm-openai:v0.8.2

# Copy the sockperf binary from the build stage
COPY --from=build-stage /usr/local/bin/sockperf /usr/local/bin/sockperf

RUN apt-get update && \
    apt-get install -y \
    infiniband-diags \
    ibverbs-utils \
    perftest \
    pciutils \
    iproute2 \
    jq \
    netcat && \
    ldconfig && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install 'ray[default]' aiohttp_cors
