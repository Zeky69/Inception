#!/bin/bash
set -e

WP_PATH="/var/www/html"

if [ -n "$WORDPRESS_DB_PASSWORD_FILE" ] && [ -f "$WORDPRESS_DB_PASSWORD_FILE" ]; then
    WORDPRESS_DB_PASSWORD=$(cat "$WORDPRESS_DB_PASSWORD_FILE")
    export WORDPRESS_DB_PASSWORD
fi

if [ -n "$WP_CREDENTIALS_FILE" ] && [ -f "$WP_CREDENTIALS_FILE" ]; then
    WP_ADMIN_PASSWORD=$(cat "$WP_CREDENTIALS_FILE")
fi

if [ -n "$WP_USER_PASSWORD_FILE" ] && [ -f "$WP_USER_PASSWORD_FILE" ]; then
    WP_USER_PASSWORD=$(cat "$WP_USER_PASSWORD_FILE")
fi

echo "Setting up WordPress..."

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp
    rm /tmp/wordpress.tar.gz

    cp -rn /tmp/wordpress/. "$WP_PATH/" || true
    rm -rf /tmp/wordpress

    echo "Downloading Redis Object Cache plugin..."
    wget -q https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip -O /tmp/redis-cache.zip
    unzip -q /tmp/redis-cache.zip -d "$WP_PATH/wp-content/plugins/"
    rm /tmp/redis-cache.zip

    WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)

    cat > "$WP_PATH/wp-config.php" << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_CACHE', true);

\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';

${WP_SALTS}

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF

    find "$WP_PATH" -type d -exec chmod 750 {} \;
    find "$WP_PATH" -type f -exec chmod 640 {} \;
    chown -R www-data:www-data "$WP_PATH"

    echo "Downloading WP-CLI..."
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
    chmod +x /usr/local/bin/wp

    echo "Waiting for Database to be ready..."
    until wp db check --allow-root --path=$WP_PATH; do
        sleep 2
    done

    echo "Installing WordPress..."
    wp core install --url=${DOMAIN_NAME} --title="${WP_TITLE}" --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASSWORD} --admin_email=${WP_ADMIN_EMAIL} --skip-email --allow-root --path=$WP_PATH

    echo "Creating standard user..."
    wp user create ${WP_USER} ${WP_USER_EMAIL} --role=author --user_pass=${WP_USER_PASSWORD} --allow-root --path=$WP_PATH || true

    echo "Enabling Redis cache..."
    wp plugin activate redis-cache --allow-root --path=$WP_PATH
    wp redis enable --allow-root --path=$WP_PATH

    echo "WordPress setup complete."
else
    echo "WordPress already initialized, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
