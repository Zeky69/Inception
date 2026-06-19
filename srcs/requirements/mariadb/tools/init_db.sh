#!/bin/bash
set -e

DB_ROOT_PASS=$(cat /run/secrets/db_root_password)
DB_PASS=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

mysqld_safe --skip-networking &
MYSQL_PID=$!

for i in $(seq 1 30); do
	if mysqladmin ping --silent 2>/dev/null; then
		break
	fi
	sleep 1
done

mysql -u root <<-EOF
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
	FLUSH PRIVILEGES;
EOF

mysqladmin -u root -p"${DB_ROOT_PASS}" shutdown
wait $MYSQL_PID

exec mysqld
