COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/zakburak/data

.PHONY: all build up down clean fclean re logs status

all: build up

# Create data directories and build images
build: $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) build

# Create data directories if they don't exist
$(DATA_DIR)/mariadb:
	mkdir -p $(DATA_DIR)/mariadb

$(DATA_DIR)/wordpress:
	mkdir -p $(DATA_DIR)/wordpress

# Start services
up:
	docker compose -f $(COMPOSE_FILE) up -d

# Stop services
down:
	docker compose -f $(COMPOSE_FILE) down

# View logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# Show status
status:
	docker compose -f $(COMPOSE_FILE) ps

# Clean containers and images
clean:
	docker compose -f $(COMPOSE_FILE) down
	docker system prune -af

# Full clean including volumes and data
fclean: clean
	docker volume prune -f
	sudo rm -rf $(DATA_DIR)/wordpress
	sudo rm -rf $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb

# Rebuild everything
re: fclean all
