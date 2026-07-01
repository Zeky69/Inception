COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/zakburak/data
ENV_FILE = srcs/.env
SECRETS = secrets/db_root_password.txt \
          secrets/db_password.txt \
          secrets/credentials.txt \
          secrets/wp_user_password.txt \
          secrets/ftp_password.txt

.PHONY: all build up down clean fclean re logs status check

all: build up

# Vérifie que .env et tous les secrets existent (et ne sont pas vides).
# Si une information manque, on affiche une erreur claire et on N'ATTEINT PAS docker.
check:
	@err=0; \
	if [ ! -f $(ENV_FILE) ]; then \
		printf '\033[31m[ERREUR]\033[0m fichier manquant: %s\n' "$(ENV_FILE)"; \
		printf '          -> cp srcs/.env.example %s puis renseignez-le\n' "$(ENV_FILE)"; \
		err=1; \
	fi; \
	for f in $(SECRETS); do \
		if [ ! -s $$f ]; then \
			printf '\033[31m[ERREUR]\033[0m secret manquant ou vide: %s\n' "$$f"; \
			err=1; \
		fi; \
	done; \
	if [ $$err -ne 0 ]; then \
		printf '\033[31mAbandon:\033[0m fournissez le .env et les secrets avant de lancer Docker.\n'; \
		exit 1; \
	fi; \
	printf '\033[32m[OK]\033[0m .env et secrets presents.\n'

build: check $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

$(DATA_DIR)/mariadb:
	mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	mkdir -p $(DATA_DIR)/wordpress

up: check
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

status:
	docker compose -f $(COMPOSE_FILE) ps

clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)/wordpress
	sudo rm -rf $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb

re: fclean all
