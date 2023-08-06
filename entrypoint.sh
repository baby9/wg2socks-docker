#!/bin/bash

MOUNTPOINT=/wg0.conf # mountpoint of the config(s)

if [ ! -e $MOUNTPOINT ]; then echo "No config file/directory/tar.gz mounted at $MOUNTPOINT" >&2; exit 1; fi

WGCF=/tmp/wg0.conf # wireguard config file path, static
WG_CONF_NAME= # config file name, only for debug output
RECONN_AFTER= # reconnect time in minutes
INTERRUPTED=0 # indicator whether program has interrupted

# catch interrupt
trap 'INTERRUPTED=1; echo "Shutting down."' INT TERM

# select new config, write out to WGCF
select_config() {

    # figure out type of file
    local mime=$(file -b --mime-type $MOUNTPOINT)

    case $mime in
        "text/plain") # config file mounted
            WG_CONF_NAME="default"
            cat $MOUNTPOINT > $WGCF

            # validate
            if [ $? -eq 0 ]; then return 0; fi
            echo "Error: cannot write $WGCF" >&2
            exit 1
        ;;
        "inode/directory") # config dir mounted
            # randomly select file from dir
            local file=$(ls -1 $MOUNTPOINT/*.conf | sort -R | tail -1)
            WG_CONF_NAME=$(basename "$file")
            cat "$file" > $WGCF

            # validate
            if [ $? -eq 0 ]; then return 0; fi
            echo "Error: cannot write '$file' to $WGCF" >&2
            exit 1
        ;;
        "application/gzip") # config .taz.gz mounted
            # randomly select file from tar
            local entry=$(tar -tzf $MOUNTPOINT | sort -R | tail -1)
            WG_CONF_NAME=$(basename "$entry")
            # write out
            tar -xzOf $MOUNTPOINT "$entry" > $WGCF

            # validate
            if [ $? -eq 0 ]; then return 0; fi
            echo "Error: cannot write archive entry '$entry' to $WGCF" >&2
            exit 1
        ;;
    esac

    echo "Error: Cannot work with $mime at $MOUNTPOINT. No config file selected." >&2
    exit 1

}

# update reconnect time
update_reconn() {
    if [[ ! "$RECONNECT_TIME" =~ ^[0-9]+(-[0-9]+){0,1}$ ]]; then RECONN_AFTER=0; return 0; fi # default to 0
    if [[ ! "$RECONNECT_TIME" =~ ^.*-.*$ ]]; then RECONN_AFTER=$RECONNECT_TIME; return 0; fi # set static if applicable

    # set randomly between range

    local s=$(sed -r 's/^([0-9]+)-[0-9]+$/\1/' <<<$RECONNECT_TIME)
    local f=$(sed -r 's/^[0-9]+-([0-9]+)$/\1/' <<<$RECONNECT_TIME)

    if [ $f -gt $s ]; then RECONN_AFTER=$(shuf -i $s-$f -n 1); return 0; fi
    RECONN_AFTER=$(shuf -i $f-$s -n 1)
}

# setup firewall to only allow wireguard interface
ifname=$(basename $WGCF)
ifname=${ifname%.*}
echo y | ufw reset > /dev/null
ufw default deny incoming
ufw default deny outgoing
ufw allow out on $ifname from any to any
ufw allow in 1080

while [ $INTERRUPTED -eq 0 ]; do
    
    # update used config and reconnect time
    select_config
    update_reconn

    # start wireguard
    wg-quick up $WGCF
    # enabling ufw without prior usage of the network interface will not work for some reason
    # so, we just use the wg iface prior to enabling ufw
    echo | nc 1.1.1.1:80
    ufw enable

    # start proxy
    /revsocks -q --port 1080 &
    SOCKS_PID="$!"
    #ufw allow in 1080

    echo "Started WireGuard with '$WG_CONF_NAME'"

    # wait for interrupt or reconnect time
    if [ 0 -lt $RECONN_AFTER ]; then
        echo "Reconnecting after $RECONN_AFTER minutes"
        sleep $((60*$RECONN_AFTER)) &
    else
        echo "No reconnect time sete. Waiting for shutdown."
        sleep infinity &
    fi
    wait $!
    
    # stop proxy
    kill -SIGTERM $SOCKS_PID
    wait $SOCKS_PID

    # stop wireguard
    wg-quick down $WGCF
    ufw disable

done

echo "Shutdown complete."