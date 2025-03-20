FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y curl gpg iputils-ping

# Get the DOCA URL from here: https://docs.nvidia.com/doca/sdk/installation+and+setup/index.html
# OR: https://developer.nvidia.com/doca-downloads?deployment_platform=Host-Server&deployment_package=DOCA-Host&target_os=Linux&Architecture=x86_64&Profile=doca-ofed&Distribution=Ubuntu
ENV DOCA_URL="https://linux.mellanox.com/public/repo/doca/2.10.0/ubuntu24.04/x86_64/"

RUN curl https://linux.mellanox.com/public/repo/doca/GPG-KEY-Mellanox.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub] ${DOCA_URL} ./" > /etc/apt/sources.list.d/doca.list && \
    apt-get update && \
    apt-get -y install doca-ofed-userspace
