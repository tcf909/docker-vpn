#!/bin/bash

VPN_PORT="1197"
DEFAULT_RTABLE='lan'

DEFAULT_GW=$(ip route | grep 'default' | awk '{print $3}');
DEFAULT_DEV=$(ip route | grep 'default' | awk '{print $5}');
DEFAULT_NET=$(ip route | grep "dev ${DEFAULT_DEV}" | awk -v device="${DEFAULT_DEV}" '$3 == device {print $1}')

echo "nameserver 209.222.18.222" > /etc/resolv.conf
echo "nameserver 209.222.18.218" >> /etc/resolv.conf
echo 200 ${DEFAULT_RTABLE} >> /etc/iproute2/rt_tables
#echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
#echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter
ip route add default via ${DEFAULT_GW} dev ${DEFAULT_DEV} table ${DEFAULT_RTABLE}
ip route add ${DEFAULT_NET} dev ${DEFAULT_DEV} table ${DEFAULT_RTABLE}
ip rule add fwmark 1 table ${DEFAULT_RTABLE}

#CLEAN IPTABLES
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables -N VPN
iptables -A VPN -j DROP

#MANGLE - PRE
iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark
iptables -t mangle -A PREROUTING -m mark ! --mark 0 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8324 -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8443 -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 32400 -j MARK --set-mark 1

#MANGLE - POST
iptables -t mangle -A POSTROUTING -j CONNMARK --save-mark

#VPN
iptables -I VPN -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I VPN -o tap+ -j ACCEPT
iptables -I VPN -o tun+ -j ACCEPT

#INPUT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i tun+ -j VPN
iptables -A INPUT -i tap+ -j VPN
#INPUT RULES
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 8324 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 8443 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 32400 -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A INPUT -j LOG --log-prefix "INPUT: DROPPING: "

#OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -o tap+ -j VPN
iptables -A OUTPUT -o tun+ -j VPN
#OUTPUT RULES
iptables -A OUTPUT -d 209.222.18.218/32 -p icmp -j ACCEPT
iptables -A OUTPUT -d 209.222.18.218/32 -p udp -m udp --dport 53 -j ACCEPT
iptables -A OUTPUT -d 209.222.18.218/32 -p tcp -m tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -d 209.222.18.222/32 -p icmp -j ACCEPT
iptables -A OUTPUT -d 209.222.18.222/32 -p udp -m udp --dport 53 -j ACCEPT
iptables -A OUTPUT -d 209.222.18.222/32 -p tcp -m tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -m owner --gid-owner vpn -j ACCEPT 2>/dev/null &&
iptables -A OUTPUT -p udp -m owner --gid-owner vpn -j ACCEPT || {
    iptables -A OUTPUT -p tcp -m tcp --dport ${VPN_PORT} -j ACCEPT
    iptables -A OUTPUT -p udp -m udp --dport ${VPN_PORT} -j ACCEPT; }
#HANDLE LOCAL CONNECTIONS
iptables -A OUTPUT ! -o tun+ -p tcp -m tcp --sport 8324 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT ! -o tap+ -p tcp -m tcp --sport 8324 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT ! -o tun+ -p tcp -m tcp --sport 8443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT ! -o tap+ -p tcp -m tcp --sport 8443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT ! -o tun+ -p tcp -m tcp --sport 32400 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT ! -o tap+ -p tcp -m tcp --sport 32400 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#iptables -A OUTPUT -j LOG --log-prefix "OUTPUT: DROPPING: "

mkdir -p /dev/net

[[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200

COUNT=0
while true; do

    VPN_SERVER="$(eval echo "\$OPENVPN_${COUNT}_SERVER")"

    if [[ -z "${VPN_SERVER}" ]]; then

        [[ "${COUNT}" == "0" ]] && exit 1

        jobs

        wait -n

        killall openvpn || exit 1

        wait

        COUNT=0

    else

        exec sg vpn -c "openvpn --config /etc/openvpn/vpn.conf --remote ${VPN_SERVER}" &

        sleep 10

        (( COUNT++ ))

    fi

done