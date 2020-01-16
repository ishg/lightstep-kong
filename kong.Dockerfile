FROM kong:latest
LABEL maintainer="ishmeet@lightstep.com"

COPY ./kong-plugin-lightstep /ishmeet/kong-plugin-lightstep/


CMD ["kong", "docker-start"]