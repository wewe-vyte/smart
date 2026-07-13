#!/bin/sh
set -e

cd /var/www/html

if [ ! -f .env ]; then
    if [ "${APP_ENV:-}" = "production" ]; then
        echo "Production environment detected and .env missing — skipping .env.example copy to avoid overriding environment variables"
    else
        cp .env.example .env 2>/dev/null || true
    fi
fi

export CACHE_STORE=${CACHE_STORE:-file}
export SESSION_DRIVER=${SESSION_DRIVER:-file}

echo "Starting Laravel with DB_CONNECTION=${DB_CONNECTION:-unset} DB_HOST=${DB_HOST:-unset} DB_PORT=${DB_PORT:-unset} DB_DATABASE=${DB_DATABASE:-unset} DB_USERNAME=${DB_USERNAME:-unset} DB_SSLMODE=${DB_SSLMODE:-unset} CACHE_STORE=$CACHE_STORE SESSION_DRIVER=$SESSION_DRIVER"

echo "PHP binary: $(which php)"
echo "PHP version: $(php -v | head -n 1)"
echo "Loaded PHP modules: $(php -m | grep -E 'pdo|pgsql' | tr '\n' ' ')"
echo "PDO drivers: $(php -r 'echo implode(",",PDO::getAvailableDrivers());')"

echo "Environment loaded from Render dashboard and .env if present"

echo "---"

mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
# ensure data dir for file cache exists
mkdir -p storage/framework/cache/data
chown -R www-data:www-data storage bootstrap/cache
chown -R www-data:www-data storage/framework/cache/data
chmod -R 775 storage bootstrap/cache
chmod -R 775 storage/framework/cache/data

if [ ! -L public/storage ]; then
    php artisan storage:link || true
fi

if [ -z "$APP_KEY" ] && ! grep -q '^APP_KEY=' .env 2>/dev/null; then
    php artisan key:generate --force --no-interaction >/dev/null 2>&1 || true
fi

php artisan optimize:clear --no-interaction || true
php artisan config:clear --no-interaction || true
php artisan route:clear --no-interaction || true
php artisan view:clear --no-interaction || true
php artisan cache:clear --no-interaction || true
# Remove any stale cached config file to prevent old DB values being used
rm -f bootstrap/cache/config.php || true
# Run migrations before caching configuration and routes
php artisan migrate --force --no-interaction || true
php artisan config:cache --no-interaction || true
php artisan route:cache --no-interaction || true
php artisan view:cache --no-interaction || true

php-fpm -D
nginx -g 'daemon off;'
