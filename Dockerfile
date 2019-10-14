FROM alpine:edge

RUN apk add --no-cache \
        tor \
        torsocks \
        git \
        make \
        gcc \
        musl-dev
RUN mkdir /data && cd /data \
    && git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone \
    && make \
    && cp su-exec /usr/local/bin/ \
    && cd .. \
    && rm -rf /data

RUN apk del \
        git \
        make \
        gcc \
        musl-dev

COPY ./torrc /etc/tor/torrc
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
VOLUME ["/var/lib/tor"]

EXPOSE 9050

# USER tor

ENTRYPOINT ["/entrypoint.sh"]
