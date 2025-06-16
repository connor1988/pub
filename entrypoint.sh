#!/bin/sh

# 配置ocserv.conf文件
configure_ocserv() {
    echo "[INFO] 配置ocserv服务器..."
    
    # 配置ipv4地址
    sed -i "/ipv4-network/c\ipv4-network = ${ipv4address}" /etc/ocserv/ocserv.conf
    sed -i "/ipv4-netmask/c\ipv4-netmask = ${ipv4mask}" /etc/ocserv/ocserv.conf

    # 配置ipv6地址
    sed -i "/ipv6-network/c\ipv6-network = ${ip6network}" /etc/ocserv/ocserv.conf

    # 配置监听端口
    sed -i "/tcp-port/c\tcp-port = ${listen_tcp_port}" /etc/ocserv/ocserv.conf
    sed -i "/udp-port/c\udp-port = ${listen_udp_port}" /etc/ocserv/ocserv.conf

    echo "[INFO] ocserv配置完成"
}

# 检查并配置IP转发
check_ip_forwarding() {
    echo "[INFO] 检查容器内核参数..."
    
    # 检查并配置IPv4转发
    if [ -f /proc/sys/net/ipv4/ip_forward ]; then
        IPV4_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
        if [ "$IPV4_FORWARD" -ne 1 ]; then
            echo "[WARN] IPv4转发未开启，正在配置..."
            
            # 修改sysctl.conf配置文件
            if grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
                sed -i 's/^net.ipv4.ip_forward.*$/net.ipv4.ip_forward=1/' /etc/sysctl.conf
            else
                echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
            fi
            
            # 应用配置
            sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
            sysctl -p /etc/sysctl.conf >/dev/null 2>&1
            
            # 验证配置
            if [ $(cat /proc/sys/net/ipv4/ip_forward) -ne 1 ]; then
                echo "[ERROR] 无法启用IPv4转发，请确保容器有足够权限"
            else
                echo "[INFO] IPv4转发已启用"
            fi
        else
            echo "[INFO] IPv4转发已开启"
        fi
    else
        echo "[ERROR] 无法检查IPv4转发设置"
    fi
    
    # 检查并配置IPv6转发
    if [ -f /proc/sys/net/ipv6/conf/all/forwarding ]; then
        IPV6_FORWARD=$(cat /proc/sys/net/ipv6/conf/all/forwarding)
        if [ "$IPV6_FORWARD" -ne 1 ]; then
            echo "[WARN] IPv6转发未开启，正在配置..."
            
            # 修改sysctl.conf配置文件
            if grep -q "^net.ipv6.conf.all.forwarding" /etc/sysctl.conf; then
                sed -i 's/^net.ipv6.conf.all.forwarding.*$/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
            else
                echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
            fi
            
            # 应用配置
            sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1
            sysctl -p /etc/sysctl.conf >/dev/null 2>&1
            
            # 验证配置
            if [ $(cat /proc/sys/net/ipv6/conf/all/forwarding) -ne 1 ]; then
                echo "[ERROR] 无法启用IPv6转发，请确保容器有足够权限"
            else
                echo "[INFO] IPv6转发已启用"
            fi
        else
            echo "[INFO] IPv6转发已开启"
        fi
    else
        echo "[INFO] 未找到IPv6转发配置文件，可能系统不支持IPv6"
    fi
    
    echo "[INFO] 内核参数检查完成"
}

# 配置NAT转发规则
configure_nat() {
    echo "[INFO] 配置NAT转发规则..."
    
    # 确保iptables规则链存在
    iptables -t nat -N OCSERV_NAT 2>/dev/null
    iptables -N OCSERV_FORWARD 2>/dev/null
    
    # 清除旧规则
    iptables -t nat -F OCSERV_NAT
    iptables -F OCSERV_FORWARD
    
    # 设置新规则
    iptables -t nat -A POSTROUTING -j OCSERV_NAT
    iptables -A FORWARD -j OCSERV_FORWARD
    
    # 添加MASQUERADE规则
    iptables -t nat -A OCSERV_NAT -j MASQUERADE
    
    # 添加TCP MSS钳位规则
    iptables -A OCSERV_FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    
    echo "[INFO] NAT转发配置完成"
}

# 主函数
main() {
    configure_ocserv
    #check_ip_forwarding
    configure_nat
    
    echo "[INFO] 容器初始化完成，启动ocserv服务..."
    exec "$@"
}

# 执行主函数
main
