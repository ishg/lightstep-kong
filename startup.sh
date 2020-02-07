#!/bin/bash
set -a
source .env
docker-compose build && docker-compose up -d 

# Setup the Plugin
echo
echo "Waiting for Kong to startup..."
sleep 5

echo
echo "Enabling LightStep plugin"
curl -X POST \
  --url "localhost:8001/plugins" \
  --data 'name=lightstep' \
  --data 'config.access_token=${LIGHTSTEP_ACCESS_TOKEN}' \
  --data 'config.collector_plaintext=true' \
  --data 'config.collector_host=satellite' \
  --data 'config.collector_port=8182' 

# Create mock service and path
echo
echo "Adding mock service"
curl -X POST \
  --url "http://localhost:8001/services/" \
  --data "name=mock-service" \
  --data "url=http://mockbin.org" 

echo
echo "Adding mock route"
curl -X POST \
  --url "http://localhost:8001/services/mock-service/routes" \
  --data "hosts[]=mockbin.org" \
  --data "paths[]=/mock" 
