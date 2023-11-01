#!/bin/sh

set -e

wg-quick up /wg0.conf
/usr/sbin/sockd
