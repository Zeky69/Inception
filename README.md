*This project has been created as part of the 42 curriculum by zakburak.*

# Inception

## Description

Inception is a system administration project that introduces the concept of containerization using Docker. The goal is to deploy a functional web infrastructure composed of multiple services running in isolated containers, orchestrated by Docker Compose.

The stack consists of:
- **NGINX** — the only entrypoint, serving HTTPS on port 443 with TLSv1.2/1.3
- **WordPress + php-fpm** — the CMS application server
- **MariaDB** — the relational database

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

This project uses **environment variables** for non-sensitive data (domain name, DB name, WP title) and **Docker secrets** for all passwords.

#### Docker Network vs Host Network
| | Docker Bridge Network | Host Network |
|---|---|---|
| Isolation | Services only talk to each other via named network | Containers share host network stack |
| Security | Services not reachable from outside unless explicitly published | All ports exposed on host |
| DNS | Automatic service discovery by container name | No Docker DNS |

This project uses a **custom bridge network** (`inception`) so containers can resolve each other by name (e.g., `mariadb`, `wordpress`) while remaining isolated from the host network.

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
   echo "YourAdminPass!" > secrets/credentials.txt
   ```

3. **Build and launch**:
   ```bash
   make
   ```

4. **Access the site**: Open `https://zakburak.42.fr` in your browser (accept the self-signed certificate).

### Makefile Commands

| Command | Description |
|---|---|
| `make` or `make up` | Build images and start all containers |
| `make down` | Stop and remove containers |
| `make stop` / `make start` | Stop / start without removing |
| `make logs` | Follow live container logs |
| `make status` | Show container status |
| `make clean` | Stop containers + prune Docker system |
| `make fclean` | Full cleanup including data volumes |
| `make re` | Full rebuild from scratch |

## Resources

### Documentation
- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX docs](https://nginx.org/en/docs/)
- [MariaDB docs](https://mariadb.com/kb/en/documentation/)
- [WP-CLI docs](https://wp-cli.org/)
- [php-fpm configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

