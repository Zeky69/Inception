LOGIN		= zakburak
DATA_DIR	= /home/$(LOGIN)/data

all: up

up: data_dirs
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

stop:
	docker compose -f srcs/docker-compose.yml stop

start:
	docker compose -f srcs/docker-compose.yml start

logs:
	docker compose -f srcs/docker-compose.yml logs -f

status:
	docker compose -f srcs/docker-compose.yml ps

data_dirs:
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb

clean: down
	docker system prune -af

fclean: down
	docker system prune -af --volumes
	sudo rm -rf $(DATA_DIR)/wordpress/*
	sudo rm -rf $(DATA_DIR)/mariadb/*

re: fclean all

.PHONY: all up down stop start logs status data_dirs clean fclean re
