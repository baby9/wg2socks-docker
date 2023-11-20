#!/bin/sh

wg-quick up /wg0.conf
/gost -L socks5://:1080?interface=wg0 > /dev/null 2>&1
