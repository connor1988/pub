FROM ubuntu:20.04

ENV OC_VERSION=0.12.6-1
USER root
RUN apt-get update \
    && apt-get install ocserv -y \
    && apt-get install gnutls-bin -y \
    && apt-get install net-tools -y \
    && apt-get install curl -y \
    && apt-get install iptables -y \
    && apt-get install vim -y \
    && apt-get clean
RUN mkdir -p /etc/ocserv/ssl
RUN mkdir -p /etc/ocserv/group
VOLUME ["/etc/ocserv"]

COPY ./entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
#RUN mv /opt/docker-entrypoint.sh /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]

#EXPOSE 443
#CMD ["systemctl", "start", "ocserv.service"]
CMD ["/usr/sbin/ocserv", "--foreground", "--pid-file", "/run/ocserv.pid", "--config", "/etc/ocserv/ocserv.conf"]
