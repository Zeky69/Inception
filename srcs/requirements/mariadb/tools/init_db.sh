#!/bin/bash
set -e

DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)

# S'assurer que le repertoire du socket existe
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# --- Initialisation uniquement au premier demarrage ---
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[MariaDB] Premier demarrage : initialisation de la base..."

	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	# Demarrer MariaDB temporairement sans reseau pour l'init
	mysqld_safe --skip-networking --socket=/run/mysqld/mysqld.sock &
	MYSQL_PID=$!

	# Attendre que MariaDB soit pret via le socket local
	echo "[MariaDB] Attente du demarrage de mysqld..."
	for i in $(seq 1 30); do
		if mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; then
			echo "[MariaDB] mysqld pret (tentative $i)."
			break
		fi
		sleep 1
	done

	# Creer la base, l'utilisateur et definir le mot de passe root
	mysql --socket=/run/mysqld/mysqld.sock -u root <<-EOF
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
		FLUSH PRIVILEGES;
EOF

	# Arreter le mysqld temporaire
	mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASS}" shutdown
	wait $MYSQL_PID

	echo "[MariaDB] Initialisation terminee."
else
	echo "[MariaDB] Base deja initialisee, demarrage direct."
fi

# --- Lancer MariaDB en foreground (PID 1) ---
echo "[MariaDB] Demarrage de mysqld..."
exec mysqld --user=mysql
