#!/bin/bash
docker-compose down
docker volume rm ${PWD##*/}_kong_data