FROM kong:1.4.3-alpine
LABEL maintainer="ishmeet@lightstep.com"

# Copy the plugin into the kong container
COPY ./kong-plugin-lightstep /plugins/kong-plugin-lightstep/

CMD ["kong", "docker-start"]