#!/bin/sh
set -e

cd /var/www/html

if [ ! -f .env ]; then
    cp .env.example .env 2>/dev/null || true
fi

export CACHE_STORE=${CACHE_STORE:-file}
export SESSION_DRIVER=${SESSION_DRIVER:-file}

echo "Starting Laravel with DB_HOST=${DB_HOST:-unset} DB_DATABASE=${DB_DATABASE:-unset} CACHE_STORE=$CACHE_STORE SESSION_DRIVER=$SESSION_DRIVER"

mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

if [ ! -L public/storage ]; then
    php artisan storage:link || true
fi

if [ -z "$APP_KEY" ] && ! grep -q '^APP_KEY=' .env 2>/dev/null; then
    php artisan key:generate --force --no-interaction >/dev/null 2>&1 || true
fi

php artisan optimize:clear || true
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear || true
php artisan config:cache
php artisan route:cache
php artisan view:cache

php-fpm -D
nginx -g 'daemon off;'
