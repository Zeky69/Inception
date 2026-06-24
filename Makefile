COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/zakburak/data

.PHONY: all build up down clean fclean re logs status

all: build up

build: srcs/.env $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

srcs/.env:
	cp srcs/.env.example srcs/.env

$(DATA_DIR)/mariadb:
	mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	mkdir -p $(DATA_DIR)/wordpress

up:
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
