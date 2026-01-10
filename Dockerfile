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

# Apache: DocumentRoot na public/ + .htaccess + BasicAuth + FORCE MPM PREFORK
RUN set -eux; \
    sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf; \
    a2enmod rewrite; \
    a2enmod auth_basic; \
    \
    # --- HARD FIX: usuń wszystkie MPM z mods-enabled i wszelkie ręczne LoadModule mpm_* ---
    rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf; \
    \
    # Usuń ręczne LoadModule mpm_* jeśli gdziekolwiek istnieją (to często jest prawdziwy winowajca)
    # 1) apache2.conf
    sed -ri '/^\s*LoadModule\s+mpm_(event|worker|prefork)_module\s+/Id' /etc/apache2/apache2.conf; \
    # 2) conf-enabled/*.conf
    find /etc/apache2/conf-enabled -type f -name "*.conf" -print0 \
      | xargs -0r sed -ri '/^\s*LoadModule\s+mpm_(event|worker|prefork)_module\s+/Id'; \
    \
    # Włącz tylko prefork
    a2enmod mpm_prefork; \
    a2dismod mpm_event mpm_worker || true; \
    \
    # Dodaj katalog symfony/public
    printf '<Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        AuthType Basic\n\
        AuthName "Restricted Area"\n\
        AuthUserFile /etc/apache2/.htpasswd\n\
        Require valid-user\n\
    </Directory>\n' > /etc/apache2/conf-available/symfony.conf; \
    a2enconf symfony; \
    \
    # Szybka weryfikacja w buildzie (w logach budowania zobaczysz jaki MPM jest aktywny)
    apachectl -V | grep -E "Server version|Server MPM" || true; \
    ls -1 /etc/apache2/mods-enabled | grep mpm || true

CMD ["apache2-foreground"]
