# Prosty obraz produkcyjny: Apache + PHP 8.2 + Symfony
FROM php:8.2-apache

# Podstawowe rozszerzenia i narzędzia
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libpq-dev \
    libzip-dev \
 && docker-php-ext-install intl pdo pdo_pgsql opcache \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer z oficjalnego obrazu
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Katalog roboczy = katalog aplikacji Symfony
WORKDIR /var/www/html

# --- KROK 1: kopiujemy definicję zależności, żeby cache builda był sensowny ---
COPY app/composer.json app/composer.lock ./

# Instalacja zależności (prod)
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

# --- KROK 2: kopiujemy resztę aplikacji ---
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
