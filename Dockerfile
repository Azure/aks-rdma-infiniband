FROM ubuntu:20.04 as debs

# Install ISO from nvidia

WORKDIR /opt/debs
COPY download.sh download.sh 
USER root
RUN bash download.sh

FROM ubuntu:20.04

COPY --from=debs /opt/debs /opt/debs
COPY entrypoint.sh /entrypoint.sh 
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


