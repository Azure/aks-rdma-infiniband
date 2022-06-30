#!/usr/bin/env bash

apt update && apt install -y curl
curl -L https://content.mellanox.com/ofed/MLNX_OFED-5.6-2.0.9.0/MLNX_OFED_LINUX-5.6-2.0.9.0-ubuntu18.04-x86_64.iso -o MLNX_OFED_LINUX-5.6-2.0.9.0-ubuntu18.04-x86_64.iso