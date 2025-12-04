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

# USTAWIAMY ENV PRZED composer install
ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV COMPOSER_ALLOW_SUPERUSER=1

# Kopiujemy aplikację
COPY app/ ./

# Teraz composer odpali cache:clear w APP_ENV=prod
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

# Apache: DocumentRoot na public/
RUN sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf \
 && a2enmod rewrite

CMD ["apache2-foreground"]
