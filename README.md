# LightStep Kong POC

## Prerequisites

You need to have a LightStep Satellite running and accessible to report data to.

Public Satellites are not currently supported

### Developer Satellite

[Start a Developer Satellite](https://docs.lightstep.com/docs/use-developer-mode) to test spans reporting to LightStep

### Local Satellite

```yaml
# docker-compose.yml
version: "2"
services:
  satellite:
    container_name: satellite
    image: lightstep/collector:latest
    environment:
      - COLLECTOR_SATELLITE_KEY=<SATELLITE_KEY>
      - COLLECTOR_POOL=kong_test_pool
      - COLLECTOR_ADMIN_PLAIN_PORT=8180
      - COLLECTOR_HTTP_PLAIN_PORT=8182
      - COLLECTOR_GRPC_PLAIN_PORT=8184
      - COLLECTOR_PLAIN_PORT=8186
    ports:
      - "5000:8000"
      - "5180:8180"
      - "5182:8182"
      - "5183:8183"
      - "5282:8282"
```

```
$ docker-compose up -d
```

Test that the satellite is working by going to `localhost:5000/diagnostics`

## Installation

Currently tested on Kong v1.4.x [Mac installation](https://docs.konghq.com/install/macos/)

Install Kong:

```bash
$ brew tap kong/kong && brew install kong
```

I tried out with Dockerized Kong but could not get it to point at the running LightStep satellite. I suspect the `kong.conf` file's DNS Resolver section can be tweaked to make it work. Stay tuned

### Configure kong

Here is an example of how to run in Declaritive mode:

1. Setup working directory

```bash
$ mkdir {{/path/to/kong/working/directory}}
$ cd {{/path/to/kong/working/directory}}
$ kong config init
$ touch kong.conf
```

2. Populate `kong.yml` file. Reference `example-kong.yml`

If using developer satellite:

```yaml
collector_port: 8360
```

If using docker-compose above:

```yaml
collector_port: 5182
access_token: <LIGHTSTEP_ACCESS_TOKEN>
```

3. Populate `kong.conf` file. Reference `example-kong.conf`

```conf
prefix = {{/path/to/kong/working/directory}}
log_level = debug
mem_cache_size = 128m
database = off
declarative_confg = {{/path/to/kong/working/directory}}/kong.yml
db_cache_ttl = 0
lua_package_path = {{/path/to/kong-plugin-lightstep}}/?.lua
```

4. Start kong

```bash
cd {{/path/to/kong-plugin-lightstep}}
kong start -c {{/path/to/kong/working/directory}}/kong.conf
```

Kong's Admin API is exposed on port 8000. Visit `localhost:8001` to see that the LightStep and key-auth plugins have been enabled

5. Test the example route

Kong's Proxy is exposed on port 8001.

```bash
$ curl -X GET http://localhost:8000/mock/request \
  -H 'Host: mockbin.org' \
  -H 'apikey: test-key'
```

6. Stop Kong

```bash
$ kong stop -p {{/path/to/kong/working/directory}}
```
