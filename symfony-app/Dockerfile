# Development Dockerfile for Symfony 6 Application

# Base image for development
FROM php:8.3-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    icu-dev \
    nginx \
    supervisor \
    bash \
    postgresql-dev \
    linux-headers \
    nodejs \
    npm \
    $PHPIZE_DEPS

# Install Yarn
RUN npm install --global yarn

# Install PHP extensions
RUN docker-php-ext-configure intl \
    && docker-php-ext-install \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        intl \
        xml \
        opcache \
        pdo \
        pdo_pgsql \
        pgsql

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create nginx user and group
RUN addgroup -g 1000 -S nginx 2>/dev/null || true \
    && adduser -u 1000 -D -S -G nginx nginx 2>/dev/null || true

# Install Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Copy configuration files if they exist
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker/php/php.ini /usr/local/etc/php/conf.d/php.ini

# Set proper permissions
RUN chown -R nginx:nginx /var/www/html \
    && chmod -R 755 /var/www/html

# Expose ports
EXPOSE 8000 9000

# Create necessary directories
RUN mkdir -p var/cache var/log public /var/log/supervisor /var/log/nginx \
    && chown -R nginx:nginx var/ public/ \
    && chmod -R 775 var/ \
    && chmod -R 755 public/

# Clear and warm up cache (only if Symfony is installed)
RUN if [ -f "bin/console" ]; then \
        php bin/console cache:clear --env=prod --no-debug || true; \
        php bin/console cache:warmup --env=prod --no-debug || true; \
    fi

# Expose port 8000
EXPOSE 8000

# Create necessary directories for supervisor
RUN mkdir -p /var/log/supervisor /var/run/supervisor \
    && chown -R nginx:nginx /var/log/supervisor /var/run/supervisor

# Copy supervisor configuration
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set the command to start supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]