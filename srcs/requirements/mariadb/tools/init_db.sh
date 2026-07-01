#!/bin/bash

set -e

if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ] && [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi
if [ -n "$MYSQL_PASSWORD_FILE" ] && [ -f "$MYSQL_PASSWORD_FILE" ]; then
    MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi

SENTINEL="/var/lib/mysql/.initialized"

if [ ! -f "$SENTINEL" ]; then
    echo "Starting MariaDB initialization..."

    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "Initializing data directory..."
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    fi

    # Bootstrap mode runs the SQL without networking and without needing a
    # root login, so it is safe to (re)run even if root already has a password
    # (e.g. a previous init was interrupted before the sentinel was written).
    echo "Running setup SQL (bootstrap mode)..."
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    touch "$SENTINEL"
    echo "Initialization complete."
else
    echo "Already initialized (sentinel found). Skipping setup."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
