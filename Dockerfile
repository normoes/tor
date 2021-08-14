FROM alpine:edge

RUN apk add --no-cache \
        tor \
        torsocks \
    && apk add --no-cache --virtual .build-dev \
        git \
        make \
        gcc \
        musl-dev \
    && mkdir /data && cd /data \
    && git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone || exit 1 \
    && make \
    && cp su-exec /usr/local/bin/ || exit 1 \
    && cd .. || exit 1 \
    && rm -rf /data \
    && apk del --no-cache \
        .build-dev \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && torsocks --version > /torsocks.txt \
    && tor --version > /tor.txt


COPY ./torrc /etc/tor/torrc
COPY ./torrc.template /etc/tor/torrc.template
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
VOLUME ["/var/lib/tor"]

EXPOSE 9050

ENV HOSTNAME=""
# ed25519 keys should be fed as hex (xxd -p mykey), and they'll be converted to bin in the container
ENV PRIVATE_KEY_HEX=""
ENV PUBLIC_KEY_HEX=""
ENV SERVICE_PORT=18081

# USER tor

ENTRYPOINT ["/entrypoint.sh"]
