# TODO: mcr base?
FROM ubuntu:18.04

# Install ISO from nvidia

WORKDIR /opt/debs
COPY download.sh download.sh 
RUN bash download.sh

COPY entrypoint.sh /entrypoint.sh 

ENTRYPOINT ["/entrypoint.sh"]


