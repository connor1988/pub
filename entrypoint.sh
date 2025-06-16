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



# 配置NAT转发规则
configure_nat() {
    echo "[INFO] 配置NAT转发规则..."
    
    
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
