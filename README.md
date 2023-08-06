This image runs a WireGuard connection and exposes it via a Socks5 proxy.

You can either mount a wireguard config file, a tar.gz archive containing multiple config files or a directory containing multiple config files to `/wg0.conf`.
The container will automatically detect what to do.

Env: `RECONNECT_TIME` - Reconnection time in minutes after WG will close the connection and reconnect, `0` to disable. Supply a range (e.g. `5-10`) to select randomly each time. Defaults to `0`.

The container needs to be started with `--privileged --cap-add NET_ADMIN`!

### run with plain docker
`/path/to/your/wg.conf` can be a wireguard config file or a directory/.tar.gz containing such files.
```
docker run -d \
    --restart=unless-stopped \
    --name=wg2socks \
    --privileged \
    --cap-add NET_ADMIN \
    -v /path/to/your/wg.conf:/wg0.conf:ro \
    -p 1080:1080 \
    zenexas/wireguard-client-socks
```

### run with docker compose
```yml
services:
    wireguard-client-socks:
        image: zenexas/wireguard-client-socks
        container_name: wg2socks
        restart: unless-stopped
        cap_add: ['NET_ADMIN']
        privileged: true
        environment: ['RECONNECT_TIME=60']
        volumes: ['./wg_confs.tar.gz:/wg0.conf:ro']
        ports: ['1080:1080'] 
```