#!/bin/ash

if [ -n "$HOSTNAME" -a -n "$PRIVATE_KEY" ]; then
    echo "'Make service directory /var/lib/tor/$SERVICE_NAME"
    mkdir -p /var/lib/tor/"$SERVICE_NAME"
    chmod 700 /var/lib/tor/"$SERVICE_NAME"
    echo "$HOSTNAME" > /var/lib/tor/"$SERVICE_NAME"/hostname
    chmod 600 /var/lib/tor/"$SERVICE_NAME"/hostname
    echo "$PRIVATE_KEY" > /var/lib/tor/"$SERVICE_NAME"/private_key
    chmod 600 /var/lib/tor/"$SERVICE_NAME"/private_key
    sed -i "s|\_\_servicename\_\_|$SERVICE_NAME|g" /etc/tor/torrc.template
    sed -i "s|\_\_serviceport\_\_|$SERVICE_PORT|g" /etc/tor/torrc.template
    cp /etc/tor/torrc.template /etc/tor/torrc
fi

chown -R tor /var/lib/tor

exec su-exec tor /usr/bin/tor -f /etc/tor/torrc
