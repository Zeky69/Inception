# User Documentation — Inception

## What services are provided?

This stack deploys a complete WordPress website accessible via HTTPS. It consists of three containers:

| Container | Role | Port |
|---|---|---|
| **nginx** | Web server / reverse proxy — only public entrypoint | 443 (HTTPS) |
| **wordpress** | PHP application server (php-fpm) | 9000 (internal only) |
| **mariadb** | MySQL-compatible database | 3306 (internal only) |

Only port **443** is accessible from outside. HTTP (port 80) is not exposed.

---

## Starting and stopping the project

All commands are run from the **root of the repository**.

### Start the project
```bash
make
# or equivalently:
make up
```
This will build the Docker images (first time only) and start all three containers in the background.

### Stop the project (containers remain)
```bash
make stop
```

### Restart stopped containers (without rebuilding)
```bash
make start
```

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

## Accessing the website

1. Make sure `zakburak.42.fr` resolves to `127.0.0.1` in your `/etc/hosts`:
   ```
   127.0.0.1   zakburak.42.fr
   ```

2. Open your browser and navigate to:
   - **Website**: `https://zakburak.42.fr`
   - **Admin panel**: `https://zakburak.42.fr/wp-admin`

> ℹ️ The SSL certificate is self-signed. Your browser will warn you — click "Advanced" → "Proceed" to continue.

---

## Credentials

All credentials are stored in the `secrets/` directory at the root of the project:

| File | Content |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | MariaDB WordPress user password |
| `secrets/credentials.txt` | WordPress admin password |

WordPress user accounts configured via `.env`:

| Variable | Value |
|---|---|
| `WP_ADMIN_USER` | WordPress administrator login |
| `WP_ADMIN_EMAIL` | Administrator email |
| `WP_USER` | Second (editor) account login |
| `WP_USER_EMAIL` | Editor email |

> ⚠️ The `secrets/` directory is listed in `.gitignore` and must **never** be committed to Git.

---

## Checking that services are running

```bash
# Show container status
make status

# Follow live logs
make logs

# Check individual container logs
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Expected output of `make status`:
```
NAME        STATUS     PORTS
mariadb     running    3306/tcp
wordpress   running    9000/tcp
nginx       running    0.0.0.0:443->443/tcp
```

### Quick connectivity test
```bash
# Test HTTPS (from the host, -k ignores the self-signed cert warning)
curl -k https://zakburak.42.fr | head -20
# Expected: WordPress HTML page
```
