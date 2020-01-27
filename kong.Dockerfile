FROM kong:1.4.3-alpine
LABEL maintainer="ishmeet@lightstep.com"

# Copy the plugin into the kong container
COPY ./kong-plugin-lightstep /plugins/kong-plugin-lightstep/

# Copy cert into Kong
# COPY ./cacert.pem /path/to/cert/cacert.pem

CMD ["kong", "docker-start"]