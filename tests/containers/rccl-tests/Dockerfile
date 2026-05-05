FROM rocm/dev-ubuntu-24.04:7.2.3 AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git make g++ libopenmpi-dev openmpi-bin libibverbs-dev librdmacm-dev rccl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/ROCm/rccl-tests.git /rccl-tests && \
    cd /rccl-tests && \
    make MPI=1 HIP_HOME=/opt/rocm RCCL_HOME=/opt/rocm MPI_HOME=/usr/lib/x86_64-linux-gnu/openmpi GPU_TARGETS=gfx942

FROM rocm/dev-ubuntu-24.04:7.2.3

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server openssh-client openmpi-bin libopenmpi-dev \
    libibverbs-dev librdmacm-dev numactl rccl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#StrictModes.*/StrictModes no/' /etc/ssh/sshd_config && \
    ssh-keygen -A

COPY --from=builder /rccl-tests/build /opt/rccl-tests/build
