# Caddy with Cloudflare extension added

FROM caddy:builder AS builder

# Add Datadog plugin: https://github.com/payintech/caddy-datadog
RUN caddy-builder \
    github.com/caddy-dns/cloudflare \
    github.com/payintech/caddy-datadog

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

