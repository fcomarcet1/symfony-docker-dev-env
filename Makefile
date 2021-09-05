#!/bin/bash

OS = $(shell uname)
UID = $(shell id -u)
DOCKER_BE = docker-dev-env-for-symfony-be

help: ## Show this help message
	@echo 'usage: make [target]'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

run: ## Start the containers
	docker network create docker-dev-env-for-symfony-network || true
	cp -n docker-compose.yml.dist docker-compose.yml || true
	cp -n .env.dist .env || true
	U_ID=${UID} docker-compose up -d

run-ro: ## Start the containers && remove orphans containers
	docker network create docker-symfony-network || true
    U_ID=${UID} docker-compose up -d --remove-orphans	

start: ## Start the containers
	docker network create docker-dev-env-for-symfony-network || true
	cp -n docker-compose.yml.dist docker-compose.yml || true
	cp -n .env.dist .env || true
	U_ID=${UID} docker-compose up -d

stop: ## Stop the containers
	U_ID=${UID} docker-compose stop

down:## Stop && remove the containers 
	U_ID=${UID} docker-compose down

restart: ## Restart the containers
	$(MAKE) stop && $(MAKE) start

build: ## Rebuilds all the containers
	docker network create docker-dev-env-for-symfony-network || true
	cp -n docker-compose.yml.dist docker-compose.yml || true
	cp -n .env.dist .env || true
	U_ID=${UID} docker-compose build

prepare: ## Runs backend commands
	$(MAKE) composer-install
	$(MAKE) migrations

# Backend commands
composer-install: ## Installs composer dependencies
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} composer install --no-interaction

migrations: ## Installs composer dependencies
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} bin/console doctrine:migration:migrate -n --allow-no-migration

be-logs: ## Tails the Symfony dev log
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} tail -f var/log/dev.log
# End backend commands

cache-clear: ## Clear symfony cache for --env=dev
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bin/console cache:clear

cache-clear-test: ## Clear symfony test cache for --env=test
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bin/console cache:clear --env=test	

ssh-be: ## bash into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bash

code-style: ## Runs php-cs to fix code styling following Symfony rules
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} php-cs-fixer fix src --rules=@Symfony

generate-ssh-keys: ## Generates SSH keys for lexik/LexikJWTAuthenticationBundle.IMPORTANT: change you pass for genarate key
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} mkdir -p config/jwt
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} openssl genrsa -passout pass:767b453a97ac019714eb7ccbce781d16 -out config/jwt/private.pem -aes256 4096
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} openssl rsa -pubout -passin pass:767b453a97ac019714eb7ccbce781d16 -in config/jwt/private.pem -out config/jwt/public.pem


.PHONY: migrations

