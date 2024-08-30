# Variables
DOCKER_REGISTRY=thientam1992
VERSION=$(shell cat VERSION)
BUILD_DIRS = Signature.API Key.API

# Map directories to tag names
TAG_NAMES = \
    Signature.API:signature-api \
    Key.API:key-api

# Define targets
.PHONY: all build push version deploy-dev deploy-prod

all: build push

build:
	@for dir in $(BUILD_DIRS); do \
		tag_name=$$(echo $(TAG_NAMES) | tr ' ' '\n' | grep $$dir | cut -d':' -f2); \
		lowercase_name=$$(echo $$tag_name | tr '[:upper:]' '[:lower:]'); \
		echo "Building $$dir with tag $$tag_name:$(VERSION)..."; \
		docker buildx build --platform=linux/amd64 -t $(DOCKER_REGISTRY)/$$lowercase_name:latest -f $$PWD/$$dir/Dockerfile . --push --no-cache || exit 1; \
	done

push:
	@echo "Pushing images to Docker Hub..."
	@for dir in $(BUILD_DIRS); do \
		tag_name=$$(echo $(TAG_NAMES) | tr ' ' '\n' | grep $$dir | cut -d':' -f2); \
		lowercase_name=$$(echo $$tag_name | tr '[:upper:]' '[:lower:]'); \
		docker push $(DOCKER_REGISTRY)/$$lowercase_name:$(VERSION) || exit 1; \
		docker push $(DOCKER_REGISTRY)/$$lowercase_name:latest || exit 1; \
	done

version:
	@echo "Incrementing version..."
	@echo $$(($(VERSION) + 1)) > VERSION

# Build and push with version increment
release: build version

# Clean up dangling images
clean:
	@docker system prune -f

# To update the version file manually
update-version:
	@read -p "Enter new version: " new_version; \
	echo $$new_version > VERSION; \
	echo "Version updated to $$new_version"

.PHONY: deploy-db
deploy-db:
	docker compose --env-file .env --compatibility --profile=prod -f docker-db.yml up -d --no-deps --build

.PHONY: deploy-tool
deploy-tool:
	docker compose --env-file .env --compatibility --profile=prod -f docker-tool.yml up -d --no-deps --build

.PHONY: deploy-all
deploy-local:
	docker compose --env-file .env --compatibility --profile=prod -f docker-db.yml -f docker-sign-api.yml -f docker-worker.yml up -d --no-deps --build 

.PHONY: deploy-api
deploy-api:
	docker compose --env-file .env --compatibility --profile=prod -f docker-sign-api.yml up -d --no-deps --build 

.PHONY: deploy-worker
deploy-worker:
	docker compose --env-file .env --compatibility --profile=prod -f docker-worker.yml up -d --no-deps --build

.PHONY: deploy-sms-api
deploy-api:
	docker compose --env-file .env --compatibility --profile=prod -f docker-sms-api.yml up -d --no-deps --build 