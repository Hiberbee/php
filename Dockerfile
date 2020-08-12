ARG phpVersion=7.4
FROM php:${phpVersion}-alpine
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
ONBUILD COPY . .
ONBUILD RUN composer install --no-progress \
         && php bin/console lint:container \
         && php bin/console lint:yaml config \
         && php bin/console lint:twig templates \
         && php bin/console lint:xliff translations \
         && php bin/console doctrine:schema:validate --skip-sync \
         && php bin/console cache:warmup \
         && tar -zcvf /app.tar.gz .
