#!/bin/bash
set -e

DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/credentials)

WP_PATH="/var/www/wordpress"

# --- Attendre que MariaDB soit pret ---
echo "[WordPress] Attente de MariaDB..."
READY=0
for i in $(seq 1 60); do
	if mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASS}" --silent 2>/dev/null; then
		echo "[WordPress] MariaDB est pret (tentative $i)."
		READY=1
		break
	fi
	echo "[WordPress] Tentative $i/60..."
	sleep 2
done

if [ $READY -eq 0 ]; then
	echo "[WordPress] ERREUR : MariaDB non disponible apres 60 tentatives. Arret."
	exit 1
fi

# --- Installer WordPress uniquement si wp-config.php est absent ---
# On ne se base PAS sur wp-login.php (present des le download)
# On verifie wp-config.php : sa presence confirme que la config DB est faite
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
	echo "[WordPress] Installation de WordPress..."

	# Telecharger le core si besoin
	if [ ! -f "${WP_PATH}/wp-login.php" ]; then
		echo "[WordPress] Telechargement du core WordPress..."
		wp core download \
			--path="${WP_PATH}" \
			--allow-root
	fi

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

	# Corriger les permissions pour que nginx puisse lire les fichiers
	chown -R www-data:www-data "${WP_PATH}"
	find "${WP_PATH}" -type d -exec chmod 755 {} \;
	find "${WP_PATH}" -type f -exec chmod 644 {} \;

	echo "[WordPress] Installation terminee."
else
	echo "[WordPress] wp-config.php trouve : WordPress deja configure, skip."
fi

# --- Lancer php-fpm en foreground (PID 1) ---
echo "[WordPress] Lancement de php-fpm..."
exec php-fpm8.2 -F
