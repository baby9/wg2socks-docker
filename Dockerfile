# Expose a WireGuard connection as SOCKS5 proxy
# SOCKS5 proxy will be available at 1080

FROM alpine

RUN true && \
    apk add --no-cache wireguard-tools openresolv ip6tables curl && \
    wget https://github.com/go-gost/gost/releases/download/v3.0.0-rc10/gost_3.0.0-rc10_linux_amd64.tar.gz -O /root/gost.tar.gz && \
    tar zxvf /root/gost.tar.gz -C /root/ && \
    mv /root/gost / && \
    rm -rf /root/* /var/cache/apk/* && \
    chmod +x /gost

HEALTHCHECK --interval=90s --timeout=15s --retries=2 --start-period=120s \
	CMD curl -fsL 'http://edge.microsoft.com/captiveportal/generate_204' --interface wg0

EXPOSE 1080
CMD wg-quick up /wg0.conf && \
    /gost -L socks5://:1080?interface=wg0
