# Caddy with Cloudflare and rate limti extensions added
FROM caddy:builder AS builder

# https://github.com/mholt/caddy-ratelimit
RUN xcaddy build --with github.com/caddy-dns/cloudflare --with github.com/mholt/caddy-ratelimit

FROM caddy:latest
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
