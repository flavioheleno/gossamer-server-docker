#============================================
# BUILD
#============================================
FROM php:8.1.2-cli-alpine3.15 AS builder

# https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
ENV TZ=:/etc/localtime

WORKDIR /usr/src

#============================================
# Dist dependencies
#============================================
RUN apk update && \
    apk add --no-cache libstdc++ && \
    apk add --no-cache $PHPIZE_DEPS curl-dev openssl-dev pcre-dev pcre2-dev zlib-dev postgresql-dev libzip-dev libpng-dev && \
    apk add --no-cache wget ca-certificates git unzip

#============================================
# Extensions
#============================================
RUN docker-php-ext-install -j$(nproc) zip && \
    docker-php-ext-enable zip && \
    docker-php-ext-install -j$(nproc) pdo_pgsql && \
    docker-php-ext-enable pdo_pgsql

#============================================
# Opcache
#============================================
RUN docker-php-ext-enable opcache && \
    echo "opcache.enabled=1" > /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=192" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.fast_shutdown=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.use_cwd=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.save_comments=0" >> /usr/local/etc/php/conf.d/opcache.ini

#============================================
# Application
#============================================
RUN wget https://github.com/paragonie/gossamer-server/archive/refs/heads/master.tar.gz && \
    tar -zxf master.tar.gz --strip=1 --directory .

#============================================
# Dependencies
#============================================
ARG COMPOSER_AUTH
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer update --no-progress --ignore-platform-reqs --no-dev --prefer-dist --optimize-autoloader --no-interaction

#============================================
# COMMAND LINE INTERFACE
#============================================
FROM php:8.1.2-cli-alpine3.15 as cli

# https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
ENV TZ=:/etc/localtime
ENV APP_ENV=:dev

#============================================
# Settings
#============================================
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "memory_limit = -1" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "zend.assertions = -1" > /usr/local/etc/php/conf.d/zend.ini

#============================================
# dumb-init
#============================================
RUN apk add --no-cache dumb-init

#============================================
# Library dependencies
#============================================
RUN apk add --no-cache libstdc++ && \
    apk add --no-cache libpq --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main/ && \
    apk add --no-cache libzip

#============================================
# Application
#============================================
COPY --from=builder --chown=www-data:www-data /usr/src/bin/ /var/www/html/bin/
COPY --from=builder --chown=www-data:www-data /usr/src/local/ /var/www/html/local/
COPY --from=builder --chown=www-data:www-data /usr/src/src/ /var/www/html/src/
COPY --from=builder --chown=www-data:www-data /usr/src/vendor/ /var/www/html/vendor/
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20210902 /usr/local/lib/php/extensions/no-debug-non-zts-20210902
COPY --from=builder /usr/local/etc/php/conf.d/*.ini /usr/local/etc/php/conf.d/

#============================================
# User
#============================================
USER www-data
WORKDIR /var/www/html/bin

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["php"]

#============================================
# FASTCGI PROCESS MANAGER
#============================================
FROM php:8.1.2-fpm-alpine3.15 as fpm

# https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
ENV TZ=:/etc/localtime
ENV APP_ENV=:dev

#============================================
# Settings
#============================================
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "zend.assertions = -1" > /usr/local/etc/php/conf.d/zend.ini && \
    echo "expose_php = 0" > /usr/local/etc/php/conf.d/expose_php.ini

#============================================
# dumb-init
#============================================
RUN apk add --no-cache dumb-init

#============================================
# Library dependencies
#============================================
RUN apk add --no-cache libstdc++ && \
    apk add --no-cache libpq --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main/ && \
    apk add --no-cache libzip

#============================================
# Application
#============================================
COPY --from=builder --chown=www-data:www-data /usr/src/local/ /var/www/html/local/
COPY --from=builder --chown=www-data:www-data /usr/src/public/ /var/www/html/public/
COPY --from=builder --chown=www-data:www-data /usr/src/src/ /var/www/html/src/
COPY --from=builder --chown=www-data:www-data /usr/src/vendor/ /var/www/html/vendor/
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20210902 /usr/local/lib/php/extensions/no-debug-non-zts-20210902
COPY --from=builder /usr/local/etc/php/conf.d/*.ini /usr/local/etc/php/conf.d/

#============================================
# User
#============================================
USER www-data
WORKDIR /var/www/html/public

EXPOSE 9000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["php-fpm"]
