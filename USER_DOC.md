# User Documentation — Inception

## What services are provided?

This stack deploys a complete web infrastructure with WordPress, caching, database management, and more. It consists of 8 containers:

| Container | Role | Port | URL |
|---|---|---|---|
| **nginx** | Web server / reverse proxy (HTTPS) | 443 | `https://zakburak.42.fr` |
| **wordpress** | PHP application server (php-fpm) | 9000 (internal) | - |
| **mariadb** | MySQL-compatible database | 3306 (internal) | - |
| **redis** | Object Cache for WordPress | 6379 (internal) | - |
| **ftp** | FTP Server (vsftpd) | 21 | `ftp://zakburak.42.fr` |
| **website** | Static Portfolio Website | 80 | `http://zakburak.42.fr` |
| **adminer** | Database management UI | 8080 | `http://zakburak.42.fr:8080` |
| **portainer** | Docker management UI | 9000 | `http://zakburak.42.fr:9000` |

---

## Starting and stopping the project

All commands are run from the **root of the repository**.

### Start the project
```bash
make
# or equivalently:
make up
```
This will build the Docker images (first time only) and start all containers in the background.

### Stop and remove containers
```bash
make down
```

### Full cleanup (removes images, volumes, and data)
```bash
make fclean
```

> ⚠️ `make fclean` deletes all stored WordPress and MariaDB data. Use with caution.

---

## Accessing the services

1. Make sure `zakburak.42.fr` resolves to `127.0.0.1` in your `/etc/hosts`:
   ```
   127.0.0.1   zakburak.42.fr
   ```

2. Open your browser and navigate to:
   - **WordPress**: `https://zakburak.42.fr`
   - **Static Website**: `http://zakburak.42.fr`
   - **Adminer**: `http://zakburak.42.fr:8080`
   - **Portainer**: `http://zakburak.42.fr:9000`
   - **FTP**: `ftp://ftpuser@zakburak.42.fr`

> ℹ️ The SSL certificate on HTTPS is self-signed. Your browser will warn you — click "Advanced" → "Proceed" to continue.

---

## Credentials

All passwords are provided via Docker Secrets in the `secrets/` directory:

| File | Content |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | MariaDB WordPress user password |
| `secrets/ftp_password.txt` | FTP user (`ftpuser`) password |
| `secrets/credentials.txt` | WordPress admin password |
| `secrets/wp_user_password.txt` | WordPress second user (editor) password |

> ⚠️ The `secrets/` directory is listed in `.gitignore` and must **never** be committed to Git.

WordPress user accounts configured via `.env`:

| Variable | Value |
|---|---|
| `WP_ADMIN_USER` | WordPress administrator login |
| `WP_ADMIN_EMAIL` | Administrator email |
| `WP_USER` | Second (editor) account login |
| `WP_USER_EMAIL` | Editor email |

---

## Checking that services are running

```bash
# Show container status
make status

# Follow live logs
make logs
```

### Quick connectivity test
```bash
# Test HTTPS (from the host, -k ignores the self-signed cert warning)
curl -k https://zakburak.42.fr | head -20
# Expected: WordPress HTML page

# Test FTP
curl 'ftp://ftpuser:FtpPass42!@zakburak.42.fr/'
# Expected: Directory listing of WordPress files
```
