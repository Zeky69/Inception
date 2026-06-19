#!/bin/bash
set -e

DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/credentials)

WP_PATH="/var/www/wordpress"

echo "[WordPress] Attente de MariaDB..."
for i in $(seq 1 30); do
	if mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASS}" --silent 2>/dev/null; then
		echo "[WordPress] MariaDB est pret."
		break
	fi
	echo "[WordPress] Tentative $i/30..."
	sleep 2
done

if [ ! -f "${WP_PATH}/wp-login.php" ]; then
	echo "[WordPress] Telechargement de WordPress..."
	wp core download \
		--path="${WP_PATH}" \
		--allow-root

	echo "[WordPress] Creation de wp-config.php..."
	wp config create \
		--path="${WP_PATH}" \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASS}" \
		--dbhost="mariadb" \
		--allow-root

	echo "[WordPress] Installation de WordPress..."
	wp core install \
		--path="${WP_PATH}" \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASS}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root

	echo "[WordPress] Creation de l'utilisateur editeur..."
	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=editor \
		--user_pass="${WP_ADMIN_PASS}" \
		--path="${WP_PATH}" \
		--allow-root

	echo "[WordPress] Installation terminee."
else
	echo "[WordPress] WordPress deja installe, skip."
fi

echo "[WordPress] Lancement de php-fpm..."
exec php-fpm8.2 -F
