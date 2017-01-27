FROM ubuntu
MAINTAINER T.C. Ferguson <tcf909@gmail.com>

#Turn off apt-get recommends and suggestions
ARG DEBIAN_FRONTEND=noninteractive
RUN printf 'APT::Get::Assume-Yes "true";\nAPT::Install-Recommends "false";\nAPT::Get::Install-Suggests "false";\n' > /etc/apt/apt.conf.d/99defaults
ENV TERM=xterm-color

ARG STANDARD_PACKAGES="curl wget ca-certificates libssl1.0.0"

RUN \
    apt-get update && \
    apt-get dist-upgrade && \
    { [ ! -z "${STANDARD_PACKAGES:-''}" ] && apt-get install $STANDARD_PACKAGES; } && \
#iTerm2 Shell Integration
    wget -O - https://iterm2.com/misc/install_shell_integration_and_utilities.sh | /bin/bash && \
#CLEANUP
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#OPENVPN
RUN \
    apt-get update && \
    apt-get install iptables openvpn procps && \
    addgroup --system vpn && \
    echo '#!/usr/bin/env bash' >/sbin/resolvconf && \
    echo 'conf=/etc/resolv.conf' >>/sbin/resolvconf && \
    echo '[[ -e $conf.orig ]] || cp -p $conf $conf.orig' >>/sbin/resolvconf && \
    echo 'if [[ "${1:-""}" == "-a" ]]; then' >>/sbin/resolvconf && \
    echo '    cat >${conf}' >>/sbin/resolvconf && \
    echo 'elif [[ "${1:-""}" == "-d" ]]; then' >>/sbin/resolvconf && \
    echo '    cat $conf.orig >$conf' >>/sbin/resolvconf && \
    echo 'fi' >> /sbin/resolvconf && \
    chmod +x /sbin/resolvconf && \
#CLEANUP
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY rootfs /

CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
