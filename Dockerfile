FROM php:8.3-apache

# Pakiety systemowe
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libpq-dev \
    libzip-dev \
 && docker-php-ext-install intl pdo pdo_pgsql opcache \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ENV przed composer install
ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV COMPOSER_ALLOW_SUPERUSER=1

# Kopiujemy aplikację
COPY app/ ./

# Instalacja zależności (cache:clear odpali się w APP_ENV=prod)
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

# Uprawnienia do cache/logów, żeby uniknąć "Permission denied"
RUN mkdir -p var/cache var/log \
    && chown -R www-data:www-data var

# Kopiujemy plik .htpasswd do Apache
COPY docker/apache/.htpasswd /etc/apache2/.htpasswd

# Apache: DocumentRoot na public/ + .htaccess + BasicAuth
RUN sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
    && a2enmod rewrite \
    && a2enmod auth_basic \
    && printf '<Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        AuthType Basic\n\
        AuthName \"Restricted Area\"\n\
        AuthUserFile /etc/apache2/.htpasswd\n\
        Require valid-user\n\
    </Directory>\n' > /etc/apache2/conf-available/symfony.conf \
    && a2enconf symfony

CMD ["apache2-foreground"]
