FROM debian:trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx libnginx-mod-http-dav-ext findutils \
    && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY trim.sh /usr/local/bin/trim-build-cache
RUN chmod 0755 /usr/local/bin/trim-build-cache

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
