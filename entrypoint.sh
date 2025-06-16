#!/bin/sh

# 增加配置ocserv.conf的配置


#新修改把echo改为sed 防止多次添加相同配置进去
#配置ipv4地址
sed -i "/ipv4-network/c\ipv4-network = ${ipv4address}" /etc/ocserv/ocserv.conf
sed -i "/ipv4-netmask/c\ipv4-netmask = ${ipv4mask}" /etc/ocserv/ocserv.conf

#配置ipv6地址
sed -i "/ipv6-network/c\ipv6-network = ${ip6network}" /etc/ocserv/ocserv.conf

#配置DNS
#sed -i "/^dns/c\dns = ${dns1}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns2}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns3}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns4}" /etc/ocserv/ocserv.conf

#配置监听端口
sed -i "/tcp-port/c\tcp-port = ${listen_tcp_port}" /etc/ocserv/ocserv.conf
sed -i "/udp-port/c\udp-port = ${listen_udp_port}" /etc/ocserv/ocserv.conf


# Open ipv4 ip forward
#sysctl -w net.ipv4.ip_forward=1
#sed -i '/net.ipv4.ip_forward/c\net.ipv4.ip_forward=1' /etc/sysctl.conf


# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

if grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
    # 如果配置存在，则替换它
    sed -i 's/^net.ipv4.ip_forward.*$/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
    # 如果不存在，则添加它
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi


if grep -q "^net.ipv6.conf.all.forwarding" /etc/sysctl.conf; then
    # 如果配置存在，则替换它
    sed -i 's/^net.ipv6.conf.all.forwarding.*$/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
else
    # 如果不存在，则添加它
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
fi



# Run OpennConnect Server
exec "$@"
