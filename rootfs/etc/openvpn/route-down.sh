#!/usr/bin/env bash
#echo "starting route down..."
VPN_REMOTE_IP="${ifconfig_remote}"
VPN_REMOTE_PORT="${trusted_port}"
VPN_LOCAL_IP="${ifconfig_local}"
VPN_DEVICE="${dev}"
VPN_GW="${route_net_gateway}"
VPN_DST="${trusted_ip}"

(ip route replace default via ${VPN_GW})

(ip route del ${VPN_DST} via ${VPN_GW})

exit 0
