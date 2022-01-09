This is the HTTPS reserve proxy configuration for https://tradingstrategy.ai for [Caddy web server](https://caddy.community/). 

We use special `Dockerimage` to build support for

* [Cloudflare plugin](https://github.com/caddy-dns/cloudflare)

* [Datadog plugin](https://github.com/payintech/caddy-datadog)

We source the website frontend from multiple servers and make them available in the same domain, same path structure, using Caddy.

The purpose of this setup is search engine optimisations and better UX.

* Proxy [web frontend to SvelteKit](https://github.com/tradingstrategy-ai/frontend)

* Proxy API access to the oracle server

* Proxy documentation to the statically hosted documentation on Netlify

* HTTPS certificates are issued by Cloudflare

* The web server is configured to ignore traffic that is not from Cloudflare edge servers, 
  to make it easier to manage malicious traffic

# Running

AT this will bind all 80 on the Docker host. HTTPS traffic is terminated by Cloudflare. 

```shell
docker-compose up -d
```

This will a start container `caddy` that terminates all [tradingstrategy.ai](https://tradingstrategy.ai) web traffic.

This setup does not have any development testing - all changes to tweak URL configuration must be done directly on the production server.
You need to have `tradingstrategy.ai` override in `/etc/hosts` to test.

# Testing

Check URls:

- https://tradingstrategy.ai
- https://candlelightdinner.tradingstrategy.ai
- https://matilda.tradingstrategy.ai

# Building and development

Build Caddy inside Docker with:

```shell
docker build
```

## Checking Dogstatd connectiong

Use `nc` command for UDP connections. 

```shell
nc -u 127.0.0.1 8125
```

Write some crap to the port and see that it is not being closed by `nc`.

