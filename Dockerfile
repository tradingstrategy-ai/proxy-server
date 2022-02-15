# Caddy with Cloudflare extension added

FROM caddy:builder AS builder


RUN xcaddy build --with github.com/caddy-dns/cloudflare

# Datadog plugin: https://github.com/payintech/caddy-datadog no longer supported

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
