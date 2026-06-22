#!/bin/bash
set -e

# Read FTP password from Docker secret
FTP_PASS=$(cat /run/secrets/ftp_password)

# Create vsftpd secure chroot dir
mkdir -p /var/run/vsftpd/empty

# vsftpd requires the user's shell to be listed in /etc/shells
# Add /bin/false so PAM doesn't block the login
grep -q "^/bin/false$" /etc/shells || echo "/bin/false" >> /etc/shells

# Create FTP user if it doesn't exist
if ! id -u ftpuser &>/dev/null; then
    useradd -d /var/www/html -s /bin/false -G www-data ftpuser
fi

# Set password
echo "ftpuser:${FTP_PASS}" | chpasswd

# Ensure wordpress volume is accessible
chown -R ftpuser:www-data /var/www/html
chmod -R 775 /var/www/html

echo "FTP server starting..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
