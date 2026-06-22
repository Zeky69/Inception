#!/bin/bash
set -e

FTP_PASS=$(cat /run/secrets/ftp_password)

mkdir -p /var/run/vsftpd/empty

grep -q "^/bin/false$" /etc/shells || echo "/bin/false" >> /etc/shells

if ! id -u ftpuser &>/dev/null; then
    useradd -d /var/www/html -s /bin/false -G www-data ftpuser
fi

echo "ftpuser:${FTP_PASS}" | chpasswd

chown -R ftpuser:www-data /var/www/html
chmod -R 775 /var/www/html

echo "FTP server starting..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
