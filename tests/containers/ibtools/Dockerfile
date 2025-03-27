FROM vllm/vllm-openai:v0.8.1

RUN apt-get update && \
    apt-get install -y \
    infiniband-diags \
    ibverbs-utils \
    perftest \
    pciutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install 'ray[default]' aiohttp_cors
