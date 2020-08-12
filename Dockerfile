ARG phpVersion=7.4
FROM php:${phpVersion}-alpine AS template
WORKDIR /usr/local/composer
ENV COMPOSER_HOME=/usr/local/composer \
    COMPOSER_BIN_DIR=/usr/local/composer/bin \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    APP_ENV=dev \
    APP_DEBUG=1
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN curl -sSLo keys.dev.pub https://composer.github.io/snapshots.pub \
 && curl -sSLo keys.tags.pub https://composer.github.io/releases.pub \
 && composer global config preferred-install dist \
 && composer global require hirak/prestissimo
ONBUILD WORKDIR /usr/local/src
ONBUILD COPY . .
ONBUILD RUN composer install --no-progress \
         && php bin/console cache:warmup
ONBUILD CMD ["php", "-S", "0.0.0.0:8080", "--docroot", "public"]


FROM template
