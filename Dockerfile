FROM tcf909/ubuntu-slim
MAINTAINER T.C. Ferguson <tcf909@gmail.com>

#OPENVPN
RUN \
    apt-get update && \
    apt-get install openvpn procps && \
    addgroup --system vpn && \
#CLEANUP
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN \
    apt-get update && \
    apt-get install net-tools iputils-ping mtr && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY rootfs /