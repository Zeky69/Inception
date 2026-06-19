# Developer Documentation — Inception

## Setting up the environment from scratch

### Prerequisites

- A Linux or macOS machine with Docker and Docker Compose installed
  - On Debian/Ubuntu: follow the [official Docker install guide](https://docs.docker.com/engine/install/debian/)
  - On Apple Silicon (M-series Macs): use UTM with a Debian ARM64 VM (see GUIDE.md)
- `make` available in your shell
- `openssl` available (for SSL cert generation inside the Dockerfile)

### 1. Clone the repository

```bash
git clone <your-repo-url> Inception
cd Inception
```

### 2. Configure the domain

Add the following line to `/etc/hosts` on the machine where you will access the site:
```bash
echo "127.0.0.1 zakburak.42.fr" | sudo tee -a /etc/hosts
```

### 3. Create the secret files

The `secrets/` directory must contain three files with plaintext passwords:

```bash
mkdir -p secrets
echo "RootPasswordHere!" > secrets/db_root_password.txt
echo "UserPasswordHere!" > secrets/db_password.txt
echo "AdminPasswordHere!" > secrets/credentials.txt
```

> ⚠️ `secrets/` is in `.gitignore`. Never commit these files.

### 4. Review the environment file

`srcs/.env` contains non-sensitive variables used by Docker Compose and the containers:

```env
DOMAIN_NAME=zakburak.42.fr
CERTS_KEY=/etc/ssl/private/zakburak.42.fr.key
CERTS_CRT=/etc/ssl/certs/zakburak.42.fr.crt
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=superuser
WP_ADMIN_EMAIL=superuser@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
```

### 5. Create the data directories (done automatically by `make`)

```bash
mkdir -p /home/zakburak/data/wordpress
mkdir -p /home/zakburak/data/mariadb
```

---

## Building and launching the project

```bash
# Build all images and start the stack
make

# Equivalent to:
docker compose -f srcs/docker-compose.yml up -d --build
```

On first run, Docker will build three images from the Dockerfiles in:
- `srcs/requirements/mariadb/`
- `srcs/requirements/wordpress/`
- `srcs/requirements/nginx/`

---

## Useful container management commands

```bash
# Show running containers
make status
# or:
docker compose -f srcs/docker-compose.yml ps

# Follow logs (all services)
make logs

# Follow logs for one service
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Open a shell in a container
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Check MariaDB directly
docker exec -it mariadb mariadb -u root -p
# (enter root password from secrets/db_root_password.txt)

# Test WordPress CLI
docker exec -it wordpress wp core is-installed --path=/var/www/wordpress --allow-root

# Rebuild a single service after changes
docker compose -f srcs/docker-compose.yml up -d --build mariadb
```

---

## Project data storage and persistence

| Volume name | Host path | Container path | Content |
|---|---|---|---|
| `mariadb_data` | `/home/zakburak/data/mariadb` | `/var/lib/mysql` | MariaDB database files |
| `wordpress_data` | `/home/zakburak/data/wordpress` | `/var/www/wordpress` | WordPress PHP files, uploads |

Volumes are defined as **named volumes** with `driver: local` + `bind` option in `docker-compose.yml`. This means data persists across `docker compose down` but is wiped by `make fclean`.

### Checking data on the host
```bash
ls /home/zakburak/data/mariadb/
# Expected: ibdata1, mysql/, performance_schema/, wordpress/

ls /home/zakburak/data/wordpress/
# Expected: wp-admin/, wp-content/, wp-includes/, wp-config.php, ...
```

---

## Repository structure

```
Inception/
├── Makefile                         # Build and lifecycle management
├── README.md                        # Project overview
├── USER_DOC.md                      # End-user documentation
├── DEV_DOC.md                       # This file
├── secrets/                         # Plaintext secrets (gitignored)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                         # Non-sensitive environment variables
    ├── docker-compose.yml           # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf   # MariaDB server config
        │   └── tools/init_db.sh     # DB init script (runs on first boot)
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf        # php-fpm pool config
        │   └── tools/init_wp.sh     # WordPress install script
        └── nginx/
            ├── Dockerfile
            └── conf/nginx.conf      # NGINX HTTPS config
```

---

## TLS / SSL

The self-signed certificate is generated at **build time** inside the NGINX Dockerfile using `openssl`. It is stored inside the image at:
- Key: `/etc/ssl/private/zakburak.42.fr.key`
- Certificate: `/etc/ssl/certs/zakburak.42.fr.crt`

Only **TLSv1.2** and **TLSv1.3** are accepted (configured in `nginx.conf`).

To verify:
```bash
# TLS 1.2 must work
openssl s_client -connect zakburak.42.fr:443 -tls1_2 </dev/null 2>/dev/null | head -3

# TLS 1.3 must work
openssl s_client -connect zakburak.42.fr:443 -tls1_3 </dev/null 2>/dev/null | head -3

# TLS 1.1 must FAIL
openssl s_client -connect zakburak.42.fr:443 -tls1_1 </dev/null 2>/dev/null | head -3
```
