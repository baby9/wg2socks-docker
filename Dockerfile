# Expose a WireGuard connection as SOCKS5 proxy
# SOCKS5 proxy will be available at 1080

FROM alpine

COPY sockd.conf /etc/
COPY entrypoint.sh /

RUN true \
  && apk add --no-cache dante-server wireguard-tools openresolv ip6tables curl \
  && rm -rf /var/cache/apk/* \
  && chmod +x /entrypoint.sh

HEALTHCHECK --interval=90s --timeout=15s --retries=2 --start-period=120s \
	CMD curl 'https://www.cloudflare.com/cdn-cgi/trace' --interface wg0 || exit 1

EXPOSE 1080
ENTRYPOINT [ "/entrypoint.sh" ]
