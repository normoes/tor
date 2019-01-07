#!/bin/sh

chown -R tor /var/lib/tor

exec su-exec tor /usr/bin/tor
