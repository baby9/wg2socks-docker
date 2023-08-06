# compile revsocks (socks5 proxy)
FROM alpine:3 AS compile
ARG proj_commit="ec32c29fbeee95136f8dea2dd6e9e742f5bc7697"
WORKDIR /compile
RUN apk add --no-cache curl gcc libc-dev
RUN curl -sSL https://github.com/emilarner/revsocks/archive/${proj_commit}.zip -o src.zip && unzip src.zip
RUN gcc -w -O2 -lpthread -o revsocks revsocks-${proj_commit}/*.c

# actual image
FROM alpine:3
RUN apk add --no-cache bash file coreutils wireguard-tools ufw curl
COPY --from=compile /compile/revsocks /
COPY entrypoint.sh /
RUN chmod +x /revsocks /entrypoint.sh

HEALTHCHECK --interval=90s --timeout=15s --retries=2 --start-period=120s \
	CMD curl 'https://www.cloudflare.com/cdn-cgi/trace' --interface wg0 || exit 1

ENTRYPOINT /entrypoint.sh