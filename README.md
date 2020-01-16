# LightStep Kong POC

## Prerequisites

- Docker and docker compose.

# Kong Postgres Example (Docker)

#### 1. Update the following template configs in `docker-compose.yml` with your values

- `<LIGHTSTEP_SATELLITE_KEY>`
- `<PATH_TO_PLUGIN_DIRECTORY>`

#### 2. Start all the services

```bash
$ docker-compose up -d
```

The compose file starts up a Postgres container, intiatlizes it with the Kong migrations, and runs a LightStep Satellite, connecting them all within a network.

#### 3. Enable the Plugin

- Kong runs the Admin API on Port 8001.
- `collector_host` should point to the satellite host, aliased as `satellite` within the docker-compose network
- `collector_port` should point to the configured satellite `HTTP_PLAIN_PORT` of the _container_, not the _host_ machine.

```bash
curl -X POST \
-- url "localhost:8001/plugins" \
--data 'name=lightstep' \
--data 'config.access_token=<YOUR_LIGHTSTEP_ACCESS_TOKEN>' \
--data 'config.collector_plaintext=true' \
--data 'config.collector_host=satellite' \
--data 'config.collector_port=8182'
```

#### 4. Add a Mock Service

```bash
curl -X POST \
  --url "http://localhost:8001/services/" \
  --data "name=mock-service" \
  --data "url=http://mockbin.org"
```

#### 5. Add a mock route

```bash
curl -X POST \
    --url "http://localhost:8001/services/mock-service/routes" \
    --data "hosts[]=mockbin.org" \
    --data "paths[]=/mock"
```

#### 6. Test the mock route

```bash
curl -X GET http://localhost:8000/mock/request -H 'Host: mockbin.org'
```

Go to `http://app.lightstep.com/<YOUR_PROJECT>/explorer` to see the traces.

# Kong Declarative Config Example (Mac)

### Developer Satellite

[Start a Developer Satellite](https://docs.lightstep.com/docs/use-developer-mode) to test spans reporting to LightStep

## Installation

Currently tested on Kong v1.4.x [Mac installation](https://docs.konghq.com/install/macos/)

Install Kong:

```bash
$ brew tap kong/kong && brew install kong
```

### Configure kong

#### 1. Setup working directory

```bash
$ mkdir {{/path/to/kong/working/directory}}
$ cd {{/path/to/kong/working/directory}}
$ kong config init
$ touch kong.conf
```

#### 2. Populate `kong.yml` file. Reference `example-kong.yml`

#### 3. Populate `kong.conf` file. Reference `example-kong.conf`

```conf
prefix = {{/path/to/kong/working/directory}}
log_level = debug
mem_cache_size = 128m
database = off
declarative_confg = {{/path/to/kong/working/directory}}/kong.yml
db_cache_ttl = 0
lua_package_path = {{/path/to/kong-plugin-lightstep}}/?.lua
```

#### 4. Start kong

```bash
cd {{/path/to/kong-plugin-lightstep}}
kong start -c {{/path/to/kong/working/directory}}/kong.conf
```

Kong's Admin API is exposed on port 8001. Visit `localhost:8001` to see that the LightStep and key-auth plugins have been enabled

#### 5. Test the example route

Kong's Proxy is exposed on port 8000.

```bash
$ curl -X GET http://localhost:8000/mock/request \
  -H 'Host: mockbin.org' \
  -H 'apikey: test-key'
```

Go to `http://app.lightstep.com/<YOUR_PROJECT>/developer-mode` to see the traces.

#### 6. Stop Kong

```bash
$ kong stop -p {{/path/to/kong/working/directory}}
```
