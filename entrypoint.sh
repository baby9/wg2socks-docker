#!/bin/sh

wg-quick up /wg0.conf
/usr/sbin/sockd
