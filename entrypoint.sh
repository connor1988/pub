#!/bin/sh

# 增加配置ocserv.conf的配置

# 新修改把echo改为sed 防止多次添加相同配置进去
# 配置ipv4地址
sed -i "/ipv4-network/c\ipv4-network = ${ipv4address}" /etc/ocserv/ocserv.conf
sed -i "/ipv4-netmask/c\ipv4-netmask = ${ipv4mask}" /etc/ocserv/ocserv.conf

# 配置ipv6地址
sed -i "/ipv6-network/c\ipv6-network = ${ip6network}" /etc/ocserv/ocserv.conf

# 配置DNS
#sed -i "/^dns/c\dns = ${dns1}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns2}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns3}" /etc/ocserv/ocserv.conf
#sed -i "/^dns/c\dns = ${dns4}" /etc/ocserv/ocserv.conf

# 配置监听端口
sed -i "/tcp-port/c\tcp-port = ${listen_tcp_port}" /etc/ocserv/ocserv.conf
sed -i "/udp-port/c\udp-port = ${listen_udp_port}" /etc/ocserv/ocserv.conf

# 检查并配置IP转发
check_ip_forwarding() {
    echo "[INFO] 检查容器内核参数..."
    
    # 检查容器是否继承了主机的IPv4转发设置
    if [ -f /proc/sys/net/ipv4/ip_forward ]; then
        IPV4_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
        if [ "$IPV4_FORWARD" -ne 1 ]; then
            echo "[WARN] IPv4转发未开启，正在容器内启用..."
            sysctl -w net.ipv4.ip_forward=1 >/dev/null
            echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
            
            # 重新检查
            if [ $(cat /proc/sys/net/ipv4/ip_forward) -ne 1 ]; then
                echo "[ERROR] 无法在容器内启用IPv4转发，请确保容器有足够权限"
            else
                echo "[INFO] 已在容器内启用IPv4转发"
            fi
        else
            echo "[INFO] IPv4转发已开启"
        fi
    else
        echo "[ERROR] 无法检查IPv4转发设置"
    fi
    
    # 检查容器是否继承了主机的IPv6转发设置
    if [ -f /proc/sys/net/ipv6/conf/all/forwarding ]; then
        IPV6_FORWARD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
        if [ "$IPV6_FORWARD" -ne 1 ]; then
            echo "[WARN] IPv6转发未开启，正在容器内启用..."
            sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
            echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
            
            # 重新检查
            if [ $(cat /proc/sys/net/ipv6/conf/all/forwarding) -ne 1 ]; then
                echo "[ERROR] 无法在容器内启用IPv6转发，请确保容器有足够权限"
            else
                echo "[INFO] 已在容器内启用IPv6转发"
            fi
        else
            echo "[INFO] IPv6转发已开启"
        fi
    else
        echo "[INFO] 未找到IPv6转发配置文件，可能系统不支持IPv6"
    fi
    
    # 应用sysctl设置
    sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true
    echo "[INFO] 容器内核参数检查完成"
}

# 执行内核参数检查
check_ip_forwarding

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Run OpennConnect Server
exec "$@"
