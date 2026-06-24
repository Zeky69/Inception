*This project has been created as part of the 42 curriculum by zakburak.*

# Inception

## Description

Inception is a system administration project that introduces the concept of containerization using Docker. The goal is to deploy a functional web infrastructure composed of multiple services running in isolated containers, orchestrated by Docker Compose.

The mandatory stack consists of:
- **NGINX** — the only entrypoint, serving HTTPS on port 443 with TLSv1.2/1.3
- **WordPress + php-fpm** — the CMS application server
- **MariaDB** — the relational database

Bonus services:
- **Redis** — object cache for WordPress
- **FTP (vsftpd)** — file access to the WordPress volume
- **Static website** — portfolio served on port 80
- **Adminer** — database management UI on port 8080
- **Portainer** — Docker management UI on port 9000

### Design Choices

#### Virtual Machines vs Docker
| | Virtual Machines | Docker |
|---|---|---|
| Isolation | Full OS-level isolation | Process-level isolation via namespaces/cgroups |
| Resource usage | Heavy (full OS per VM) | Lightweight (shared kernel) |
| Startup time | Minutes | Seconds |
| Portability | Limited | High (image = portable artifact) |
| Use case | Strong isolation, different OS | Microservices, fast deployment |

Docker containers share the host kernel but are isolated through Linux namespaces and cgroups. This makes them much lighter than VMs while still providing a meaningful level of isolation.

#### Secrets vs Environment Variables
| | Environment Variables | Docker Secrets |
|---|---|---|
| Visibility | Visible in `docker inspect`, process env | Mounted as tmpfs at `/run/secrets/`, not exposed |
| Git risk | Risk of committing `.env` with passwords | Files stored separately, easy to gitignore |
| Best for | Non-sensitive config (domain, usernames) | Passwords, API keys, credentials |

This project uses **environment variables** for non-sensitive data (domain name, DB name) and **Docker secrets** for all passwords.

#### Docker Network vs Host Network
| | Docker Bridge Network | Host Network |
|---|---|---|
| Isolation | Services only talk to each other via named network | Containers share host network stack |
| Security | Services not reachable from outside unless explicitly published | All ports exposed on host |
| DNS | Automatic service discovery by container name | No Docker DNS |

This project uses a **custom bridge network** (`inception-network`) so containers can resolve each other by name (e.g., `mariadb`, `wordpress`) while remaining isolated from the host network.

#### Docker Volumes vs Bind Mounts
| | Docker Volumes | Bind Mounts |
|---|---|---|
| Managed by | Docker daemon | Host filesystem path |
| Portability | Fully portable | Host path must exist |
| Performance | Optimized | Depends on host FS |
| Use case | Production data persistence | Development, config injection |

This project uses **named volumes with `driver: local` and `bind` options** — this satisfies the subject requirement of using volumes while binding data to `/home/zakburak/data/` for persistence and easy access.

## Instructions

### Prerequisites
- Docker and Docker Compose installed
- Domain `zakburak.42.fr` pointing to `127.0.0.1` in `/etc/hosts`
- Secret files present in `secrets/` directory

### Setup

1. **Configure `/etc/hosts`**:
   ```bash
   echo "127.0.0.1 zakburak.42.fr" | sudo tee -a /etc/hosts
   ```

2. **Create secret files**:
   ```bash
   echo "YourRootPass!" > secrets/db_root_password.txt
   echo "YourUserPass!" > secrets/db_password.txt
   echo "YourFtpPass!"  > secrets/ftp_password.txt
   echo "YourAdminPass!" > secrets/credentials.txt
   echo "YourEditorPass!" > secrets/wp_user_password.txt
   chmod 600 secrets/*
   ```

3. **Build and launch**:
   ```bash
   make
   ```

4. **Access the site**: Open `https://zakburak.42.fr` in your browser (accept the self-signed certificate). Complete the WordPress installation wizard on first visit.

### Makefile Commands

| Command | Description |
|---|---|
| `make` | Build images and start all containers |
| `make build` | Build Docker images only |
| `make up` | Start containers (already built) |
| `make down` | Stop and remove containers |
| `make logs` | Follow live container logs |
| `make status` | Show container status |
| `make clean` | Stop containers + prune Docker system |
| `make fclean` | Full cleanup including data volumes |
| `make re` | Full rebuild from scratch |

### Access URLs

| Service | URL |
|---|---|
| WordPress | `https://zakburak.42.fr` |
| Static website | `http://zakburak.42.fr` |
| Adminer | `http://zakburak.42.fr:8080` |
| Portainer | `http://zakburak.42.fr:9000` |
| FTP | `ftp://zakburak.42.fr` (user: `ftpuser`) |

## Resources

### Documentation
- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX docs](https://nginx.org/en/docs/)
- [MariaDB docs](https://mariadb.com/kb/en/documentation/)
- [php-fpm configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [vsftpd documentation](https://security.appspot.com/vsftpd.html)
- [Redis documentation](https://redis.io/docs/)
- [Adminer](https://www.adminer.org/)
- [Portainer CE](https://docs.portainer.io/)
- [Tutorial: Docker NGINX + WordPress + MariaDB (dev.to)](https://dev.to/alejiri/docker-nginx-wordpress-mariadb-tutorial-inception42-3po3)

### AI Usage
AI tools (Gemini/Antigravity) were used during this project as a pair-programming assistant for:
- Debugging container startup issues (MariaDB socket path, sentinel file, PHP-FPM configuration)
- Reviewing and fixing shell scripts (`init_db.sh`, `setup_wordpress.sh`, `generate_ssl.sh`)
- Structuring the Docker Compose file and secrets management
- Implementing bonus services (Redis cache, vsftpd, Adminer, Portainer)

All generated code was reviewed, understood, and adapted to the project's specific constraints before being committed.
