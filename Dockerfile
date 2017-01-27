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

COPY rootfs /

CMD ["/run"]
#
