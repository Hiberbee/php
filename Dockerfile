ARG phpVersion=7.4
FROM php:${phpVersion}-alpine AS build
LABEL org.opencontainers.image.title="PHP / Symfony Docker image template" \
      org.opencontainers.image.vendor="Hiberbee" \
      org.opencontainers.image.authors="Vlad Volkov <vlad@hiberbee.com>" \
      org.opencontainers.image.source="https://github.com/hiberbee/template-php-symfony"
WORKDIR /usr/local/composer
ENV COMPOSER_HOME=/usr/local/composer \
    COMPOSER_BIN_DIR=/usr/local/composer/bin \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN curl -sSLo keys.dev.pub https://composer.github.io/snapshots.pub \
 && curl -sSLo keys.tags.pub https://composer.github.io/releases.pub \
 && composer global config preferred-install dist \
 && composer global require hirak/prestissimo
ONBUILD ARG env=dev
ONBUILD ARG debug=1
ONBUILD ENV APP_ENV=${env} \
            APP_DEBUG=${debug}
ONBUILD WORKDIR /usr/local/src
ONBUILD COPY composer.* symfony.lock ./
ONBUILD RUN composer install \
              --no-autoloader \
              --no-interaction \
              --no-progress \
              --no-scripts
ONBUILD COPY . .
ONBUILD RUN composer dump-autoload \
              --optimize \
              --apcu \
              --no-dev \
              --classmap-authoritative \
              --no-interaction \
         && composer run-script auto-scripts \
         && tar -zcf /app.tar.gz .

FROM php:7.4-alpine AS runtime
WORKDIR /usr/local/src
COPY --from=build /app.tar.gz .
RUN tar --extract --gzip --file=app.tar.gz \
 && rm -rf app.tar.gz
ENTRYPOINT ["php"]
CMD ["--server", "0.0.0.0:8080", "--docroot", "public"]
