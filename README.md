# Description

This is the HTTPS reverse proxy configuration for https://tradingstrategy.ai for [Caddy web server](https://caddy.community/).

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

* [Caddy OpenMetrics endpoint](https://caddyserver.com/docs/metrics)

## Development flow

- Git checkout
- Edit `Caddyfile` config file locally
- Check syntax with `caddy validate --config Caddyfile`
- Sync `Caddyfile` to server
- Restart the production Docker

## Running

AT this will bind all 80 on the Docker host. HTTPS traffic is terminated by Cloudflare.

```shell
# Start the service
docker-compose up -d
```

This will a start container `caddy` that terminates all [tradingstrategy.ai](https://tradingstrategy.ai) web traffic.

This setup does not have any development testing - all changes to tweak URL configuration must be done directly on the production server.
You need to have `tradingstrategy.ai` override in `/etc/hosts` to test.

# Restarting Caddy on production and makign config changes

Get an updated `Caddyfile` and then run

```shell
# Use caddy validate from Docker image to validate our config file
docker run -v ${PWD}/Caddyfile:/tmp/Caddyfile caddy:v2.4.5 caddy validate --config /tmp/Caddyfile

docker-compose up --force-recreate -d
```

Caddy and caddy-logstash should be running

Caddy-logstash should have the following ENV variables set:

```yaml
  ECS_SERVER: ${ECS_SERVER}
  ECS_USER: ${ECS_USER}
  ECS_PASSWORD: ${ECS_PASSWORD}
```

```shell

# Testing

Check URls:

- https://tradingstrategy.ai
- https://tradingstrategy.ai/api/explorer/
- https://tradingstrategy.ai/docs

# Diagnosing

Manually checking error counts:

```shell
curl http://127.0.0.1:6000/metrics|grep -i error
```

Ready Caddy logs real time:

```shell
tail -f logs/access.log
```

Reading logs using `jq` ([See blog post](https://caddy.community/t/making-caddy-logs-more-readable/7565)).
This will show status code, URL, IP address as a tail follow.

```shell
tail -f logs/access.log | jq '[.status, .request.remote_addr, .request.uri] | join(" ")'
```

```
"200 x:61170 /api/xyliquidity?pair_id=60282&time_bucket=1d"
"200 x:22642 /api/pair-details?chain_slug=ethereum&exchange_slug=uniswap-v2&pair_slug=akeno-eth"
"200 x:20432 /api/xyliquidity?pair_id=60291&time_bucket=1d"
"200 x:45076 /api/pair-details?chain_
```

# Metrics

Metrics are expored on `http://127.0.0.1:6000/metrics`. Note that the port binding works on Linux only.

To test the metrics endpoint:

```python
curl http://127.0.0.1:6000/metrics
```

[See example of available metrics OpenMetrics](./metrics.md)

## Datadog integration

You can make [Datadog agent to read OpenMetrics](https://docs.datadoghq.com/integrations/openmetrics/) from Caddy endpoint.

On the reverse proxy host, Go to DataDog OpenMetrics plugin directory and enable OpenMetrics:

```shell
/etc/datadog-agent/conf.d/openmetrics.d
mv conf.yaml.example conf.yaml
```

Edit `conf.yaml`:

```yaml
instances:

  - openmetrics_endpoint: http://127.0.0.1:6000/metrics

    namespace: caddy

    metrics: ["caddy*"]
```

Restart agent:

```shell
sudo service datadog-agent restart
```

Give it 1 minute. Then check the OpenMetrics plugin is running:

```shell
datadog-agent status|grep -C 30 openmetrics
```

It should be running:

```
    openmetrics (1.15.2)
    --------------------
      Instance ID: openmetrics:caddy:17dd45bf18763b62 [OK]
      Configuration Source: file:/etc/datadog-agent/conf.d/openmetrics.d/conf.yaml
      Total Runs: 41
      Metric Samples: Last Run: 657, Total: 26,937
      Events: Last Run: 0, Total: 0
      Service Checks: Last Run: 1, Total: 41
      Average Execution Time : 27ms
      Last Execution Date : 2022-01-09 21:11:18 CET / 2022-01-09 20:11:18 UTC (1641759078000)
      Last Successful Execution Date : 2022-01-09 21:11:18 CET / 2022-01-09 20:11:18 UTC (1641759078000)
```

# Building and development

Build Caddy inside Docker with:

```shell
docker build

```
Write some crap to the port and see that it is not being closed by `nc`.

# Logs

Stdout logs:

```
docker-compose logs caddy
```

File logs (needs a big screen or small font):

```
docker-compose exec -it caddy tail -f /var/log/caddy/access.log | jq .
```

Checking for specific string in logs

```shell
docker-compose exec -it caddy tail -f /var/log/caddy/access.log | grep por-que | jq .
```

# Notes

* [Docker network_mode: host containers do not work on macOS](https://github.com/docker/for-mac/issues/155)

* [DataDog OpenMetrcis checks source code](https://github.com/DataDog/integrations-core/blob/master/datadog_checks_base/datadog_checks/base/checks/openmetrics/v2/base.py)
