FROM kong:1.4.3-alpine
LABEL maintainer="ishmeet@lightstep.com"

COPY ./kong-plugin-lightstep /plugins/kong-plugin-lightstep/

CMD ["kong", "docker-start"]