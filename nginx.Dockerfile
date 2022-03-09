FROM nginx:mainline-alpine

# https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
ENV TZ=:/etc/localtime

# default PHP-FPM upstream server name
ENV PHP_FPM=php-fpm

# nginx settings
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/upstream.conf.template /etc/nginx/templates/upstream.conf.template

#============================================
# Healthcheck
#============================================
HEALTHCHECK --interval=1m30s --timeout=10s --retries=3 --start-period=40s CMD curl -f http://localhost/status || exit 1

#============================================
# Metadata
#============================================
LABEL org.opencontainers.image.authors="flaviohbatista@gmail.com" \
      org.opencontainers.image.title="Gossamer-Server-NGINX" \
      org.opencontainers.image.url="https://github.com/flavioheleno/gossamer-server-docker" \
      org.opencontainers.image.vendor="flavioheleno"

WORKDIR /usr/share/nginx/html
