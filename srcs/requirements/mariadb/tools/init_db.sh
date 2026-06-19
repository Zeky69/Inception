#!/bin/bash
set -e

DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)

# --- Initialisation uniquement si la base n'existe pas encore ---
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[MariaDB] Premier démarrage : initialisation de la base..."

	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	# Demarrer MariaDB temporairement (sans reseau) pour l'init
	mysqld_safe --skip-networking &
	MYSQL_PID=$!

	# Attendre que MariaDB soit pret
	for i in $(seq 1 30); do
		if mysqladmin ping --silent 2>/dev/null; then
			break
		fi
		sleep 1
	done

	# Creer la base, l'utilisateur et le mot de passe root
	mysql -u root <<-EOF
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
		FLUSH PRIVILEGES;
EOF

	# Arreter le MariaDB temporaire proprement
	mysqladmin -u root -p"${DB_ROOT_PASS}" shutdown
	wait $MYSQL_PID

	echo "[MariaDB] Initialisation terminée."
else
	echo "[MariaDB] Base déjà initialisée, démarrage direct."
fi

# Lancer MariaDB en foreground (PID 1)
exec mysqld
