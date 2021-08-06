#!/bin/ash

if [ -n "$HOSTNAME" -a -n "$PRIVATE_KEY_HEX" -a -n "$PUBLIC_KEY_HEX" ]; then
    echo "'Make service directory /var/lib/tor/$SERVICE_NAME"
    mkdir -p /var/lib/tor/"$HOSTNAME"
    chmod 700 /var/lib/tor/"$HOSTNAME"

    echo "$HOSTNAME" > /var/lib/tor/"$HOSTNAME"/hostname
    chmod 600 /var/lib/tor/"$HOSTNAME"/hostname

    echo "$PRIVATE_KEY_HEX" | xxd -r -p > /var/lib/tor/"$HOSTNAME"/hs_ed25519_secret_key
    chmod 600 /var/lib/tor/"$HOSTNAME"/hs_ed25519_secret_key

    echo "$PUBLIC_KEY_HEX" | xxd -r -p > /var/lib/tor/"$HOSTNAME"/hs_ed25519_public_key
    chmod 600 /var/lib/tor/"$HOSTNAME"/hs_ed25519_public_key

    sed -i "s|\_\_servicename\_\_|$HOSTNAME|g" /etc/tor/torrc.template
    sed -i "s|\_\_serviceport\_\_|$SERVICE_PORT|g" /etc/tor/torrc.template
    cp /etc/tor/torrc.template /etc/tor/torrc
fi

chown -R tor /var/lib/tor

exec su-exec tor /usr/bin/tor -f /etc/tor/torrc
