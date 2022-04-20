#
# Edit the Makefile variables below as described:
#
# PATTERN_NAME      - a name of your choice for your open-horizon Pattern
# SERVICE_NAME      - a name of your choice for your open-horizon Service
# SERVICE_VERSION   - version (in format N.N.N) for your open-horizon Service
# SERVICE_CONTAINER - your full container ID (registry/repo:version)
# CONTAINER_CREDS   - optional container access creds (registry/repo:user:token)
# ARCH              - an open-horizon architecture (see `hzn architecture`)
#

PATTERN_NAME:="papermc-server-pattern"
SERVICE_NAME:="papermc-server-server"
SERVICE_VERSION:="1.0.0"
SERVICE_CONTAINER:="https://hub.docker.com/r/marctv/minecraft-papermc-server:1.18"
CONTAINER_CREDS:=
ARCH:="amd64"

publish-service: validate-org
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        SERVICE_CONTAINER="$(SERVICE_CONTAINER)" \
        hzn exchange service publish -O $(CONTAINER_CREDS) -f service.json --pull-image

publish-pattern: validate-org
	@ARCH=$(ARCH) \
        SERVICE_NAME="$(SERVICE_NAME)" \
        SERVICE_VERSION="$(SERVICE_VERSION)"\
        PATTERN_NAME="$(PATTERN_NAME)" \
	hzn exchange pattern publish -f pattern.json

register-pattern: validate-org
	hzn register --pattern "${HZN_ORG_ID}/$(PATTERN_NAME)"

validate-org:
	@if [ -z "${HZN_ORG_ID}" ]; \
          then { echo "***** ERROR: \"HZN_ORG_ID\" is not set!"; exit 1; }; \
          else echo "Using Exchange Org ID: \"${HZN_ORG_ID}\""; \
        fi
	@sleep 1

clean:
	-hzn unregister -f
	-hzn exchange pattern remove -f "${HZN_ORG_ID}/$(PATTERN_NAME)"
	-hzn exchange service remove -f "${HZN_ORG_ID}/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)"
	-docker rmi -f "$(SERVICE_CONTAINER)"

.PHONY: publish-service publish-pattern register-pattern validate-org clean help

help: ## prints this message ##
	@echo ""; \
	echo "Usage: make <command>"; \
	echo ""; \
	echo "where <command> is one of the following:"; \
	echo ""; \
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	perl -nle '/(.*?): ## (.*?) ## (.*$$)/; if ($$3 eq "") { printf ( "$(COMMAND_COLOR)%-20s$(DESC_COLOR)%s$(CLEAR_COLOR)\n\n", $$1, $$2) } else { printf ( "$(COMMAND_COLOR)%-20s$(DESC_COLOR)%s$(CLEAR_COLOR)\n%-20s%s\n\n", $$1, $$2, " ", $$3) }';

.PHONY: start
start: ## docker-compose up --build ## (starts the minecraft server)
	@echo "Starting Minecraft Server..."; \
	docker-compose up -d --build;

.PHONY: stop
stop: ## docker-compose stop --rmi all --remove-orphans: ## (stops and cleans up images, but keeps data)
	@echo "Stopping Minecraft Server and cleaning up..."; \
	docker-compose down --rmi all --remove-orphans;

.PHONY: attach
attach: ## docker attach mcserver ## (attaches to minecraft paper jar for issuing commands)
	@echo "Attaching to Minecraft..."; \
	echo "Ctrl-C stops minecraft and exits"; \
	echo "Ctrl-P Ctrl-Q only exits"; \
	echo ""; \
	echo "Type "help" for help."; \
	docker attach mcserver;
