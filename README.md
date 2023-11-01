
Expose WireGuard as a SOCKS5 proxy in a Docker container.

## Usage
Replace your wireguard config file path in `/path/to/your/wg.conf`
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

SOCKS5 proxy server will be listening at port 1080.

<br/><br/>
Connect to your socks5 proxy. For example:

````
curl -s -x socks5://127.0.0.1:1080 https://ipinfo.io
````
