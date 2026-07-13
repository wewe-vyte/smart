FROM php:8.2-fpm

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    ca-certificates \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    nginx \
    nodejs \
    npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo_mysql mbstring zip exif bcmath pcntl gd intl \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . .
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

RUN if [ -f package.json ]; then npm install --no-audit --no-fund && npm run build; fi \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && cp start.sh /usr/local/bin/start.sh \
    && chmod +x /usr/local/bin/start.sh

COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["/usr/local/bin/start.sh"]
