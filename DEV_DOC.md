# Developer Documentation — Inception

## Setting up the environment from scratch

### Prerequisites

- A Linux or macOS machine with Docker and Docker Compose installed
  - On Debian/Ubuntu: follow the [official Docker install guide](https://docs.docker.com/engine/install/debian/)
  - On Apple Silicon (M-series Macs): use UTM with a Debian ARM64 VM (see GUIDE.md)
- `make` available in your shell
- `openssl` available

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

The `secrets/` directory must contain five files with plaintext passwords:

```bash
mkdir -p secrets
echo "RootPasswordHere!"    > secrets/db_root_password.txt
echo "UserPasswordHere!"    > secrets/db_password.txt
echo "FtpPasswordHere!"     > secrets/ftp_password.txt
echo "AdminPasswordHere!"   > secrets/credentials.txt
echo "WpUserPasswordHere!"  > secrets/wp_user_password.txt
chmod 600 secrets/*
```

| File | Used by | Purpose |
|------|---------|---------|
| `db_root_password.txt` | mariadb | MariaDB root password |
| `db_password.txt` | mariadb, wordpress | WordPress DB user password |
| `ftp_password.txt` | ftp | `ftpuser` FTP password |
| `credentials.txt` | wordpress | WordPress **admin** password |
| `wp_user_password.txt` | wordpress | WordPress **second user** (editor/author) password |

> ⚠️ `secrets/` is in `.gitignore`. Never commit these files.

### 4. Review the environment file

`srcs/.env` is **not committed** (it is gitignored). A template `srcs/.env.example` is
provided instead — running `make` copies it to `srcs/.env` automatically if it is missing.
It contains only non-sensitive variables used by Docker Compose and the containers:

```env
DOMAIN_NAME=zakburak.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_HOST=mariadb
WORDPRESS_TABLE_PREFIX=wp_
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

On first run, Docker will build 8 images from the Dockerfiles in:
- `srcs/requirements/mariadb/`
- `srcs/requirements/wordpress/`
- `srcs/requirements/nginx/`
- `srcs/requirements/bonus/redis/`
- `srcs/requirements/bonus/ftp/`
- `srcs/requirements/bonus/website/`
- `srcs/requirements/bonus/adminer/`
- `srcs/requirements/bonus/portainer/`

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

# Open a shell in a container
docker exec -it mariadb bash
docker exec -it wordpress bash

# Check MariaDB directly
docker exec -it mariadb mysql -u root -p
# (enter root password from secrets/db_root_password.txt)

# Rebuild a single service after changes
docker compose -f srcs/docker-compose.yml up -d --build mariadb
```

---

## Project data storage and persistence

| Volume name | Host path | Container path | Content |
|---|---|---|---|
| `mariadb_data` | `/home/zakburak/data/mariadb` | `/var/lib/mysql` | MariaDB database files |
| `wordpress_data` | `/home/zakburak/data/wordpress` | `/var/www/html` | WordPress PHP files, uploads |
| `portainer_data` | docker local volume | `/data` | Portainer configuration |

Volumes are defined as **named volumes** with `driver: local` + `bind` option in `docker-compose.yml`. This means data persists across `docker compose down` but is wiped by `make fclean`.

### Checking data on the host
```bash
ls /home/zakburak/data/mariadb/
ls /home/zakburak/data/wordpress/
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
└── srcs/
    ├── .env.example                 # Template (committed); copied to .env by `make`
    ├── .env                         # Non-sensitive env vars (gitignored, auto-generated)
    ├── docker-compose.yml           # Service orchestration
    └── requirements/
        ├── mariadb/                 # MariaDB container
        ├── wordpress/               # WordPress + php-fpm container
        ├── nginx/                   # NGINX container
        └── bonus/
            ├── redis/               # Redis cache
            ├── ftp/                 # vsftpd FTP server
            ├── website/             # Static portfolio site
            ├── adminer/             # Adminer database management
            └── portainer/           # Portainer Docker UI
```

---

## TLS / SSL

The self-signed certificate is generated at **runtime** when the NGINX container starts using `tools/generate_ssl.sh`. It is stored inside the container at:
- Key: `/etc/nginx/ssl/nginx.key`
- Certificate: `/etc/nginx/ssl/nginx.crt`

Only **TLSv1.2** and **TLSv1.3** are accepted (configured in `nginx.conf`).
