FROM php:8.3-apache

# Podstawowe rozszerzenia i narzędzia
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libpq-dev \
    libzip-dev \
 && docker-php-ext-install intl pdo pdo_pgsql opcache \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY app/composer.json app/composer.lock ./

RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

COPY app/ ./

# Apache: DocumentRoot na public/
RUN sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri 's!/var/www/!/var/www/html/public!g' /etc/apache2/apache2.conf \
 && a2enmod rewrite

# Symfony ENV
ENV APP_ENV=prod
ENV APP_DEBUG=0

# Railway daje zewnętrzny PORT, ale Apache wewnątrz słucha na 80 - to jest OK

CMD ["apache2-foreground"]
