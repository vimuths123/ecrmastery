# ------------------------------
# Stage 1: Build Composer vendors
# ------------------------------
FROM public.ecr.aws/composer/composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-progress --prefer-dist --optimize-autoloader

COPY . .
RUN composer dump-autoload --optimize


# ------------------------------
# Stage 2: Production Image
# ------------------------------
FROM public.ecr.aws/docker/library/php:8.3-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpq-dev libonig-dev libxml2-dev \
    libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring zip exif pcntl bcmath

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install Composer globally
COPY --from=vendor /usr/bin/composer /usr/bin/composer

# Copy app from builder
WORKDIR /var/www/html
COPY . .
COPY --from=vendor /app/vendor ./vendor

# Laravel permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

CMD ["php-fpm"]
