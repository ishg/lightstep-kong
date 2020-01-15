# Getting Started

## Run a LightStep Satellite

```bash
docker run \
-e COLLECTOR_SATELLITE_KEY=<SATELLITE_KEY> \
-e COLLECTOR_DIGNOSTIC_PORT=8000 -p 5000:8000 \
-e COLLECTOR_HTTP_PLAIN_PORT=8182 -p 5182:8182 \
lightstep/collector:latest
```

## Enable the Plugin

The plugin is not in the official Kong directory yet, so use the [declarative config example](https://github.com/ishg/lightstep-kong)

```yaml
plugins:
  - name: lightstep
    config:
      collector_host: localhost
      collector_port: 5182
      collector_plaintext: true
      access_token: <LIGHTSTEP_ACCESS_TOKEN>
      component_name: lightstep-kong
      sample_ratio: 1
      include_credential: true
```

# Implementation

The LightStep plugin is derived from an OpenTracing base.

A tracer is created with the "http_headers" formatter set to use the OpenTracing headers (not B3 yet)

## Spans

- _Request span_: 1 per request. Encompasses the whole request in kong (`kind: server`). The proxy span and the balancer spans are children of this span. Contains logs for the `kong.rewrite` phase start and end.
- _Proxy span_: 1 per request. Encompassing most of Kong's internal processing of a request (`kind: client`). Contains logs for the start/end of the rest of kong phases: `kong.access`, `kong.header_filter`, `kong.body_filter`, `kong.preread`
- _Balancer span(s)_: 0 or more per request, each encompassing one balancer attempt(`kind: client`). Contains tags specific to the load balancing:
  - `kong.balancer.try`: a number indicating the attempt order
  - `peer.ipv4`/`peer.ipv6` + `peer.port` for the balanced port
  - `error`: true/false depending on whether the balancing could be done or not
  - `http.status_code`: the http status code received, in case of error
  - `kong.balancer.state`: an nginx-specific description of the error: `next`/`failed` for HTTP failures, `0` for stream failures. Equivalent to `state_name` in [OpenResty's Balancer's `get_last_failure` function](https://github.com/openresty/lua-resty-core/blob/master/lib/ngx/balancer.md#get_last_failure).

## Tags

### Standard Tags

- `span.kind`
- `http.method`
- `http.status_code`
- `http.path`
- `error`
- `peer.ipv4`
- `peer.ipv6`
- `peer.port`
- `peer.hostname`
- `peer.service`

## Non-Standard Tags

- `kong.api` (deprecated)
- `kong.consumer.id`
- `kong.consumer.name`
- `kong.credential`
- `kong.credential`
- `kong.node.id`
- `kong.route.id`
- `kong.route.name`
- `kong.service.id`
- `kong.service.name`
- `kong.balancer.try`
- `kong.balancer.state`

## Logs

_Due to some limitations, this plugin's timestamp resolution is in seconds_
Logs are used to encode the begin and end of every kong phase.

- `kong.rewrite`, `start` / `finish`, `<timestamp>`
- `kong.access`, `start` / `finish`, `<timestamp>`
- `kong.preread`, `start` / `finish`, `<timestamp>`
- `kong.header_filter`, `start` / `finish`, `<timestamp>`
- `kong.body_filter`, `start` / `finish`, `<timestamp>`

# TODOS

1. Support HTTPS
2. Implement unique reporter id
3. Implement baggage items in span context
4. Implement b3 header propagation
5. Test with Traces starting at upstream and downstream services
6. Get finer time resolution
