# Ensure that every command in this Makefile
# will run with bash instead of the default sh
SHELL := /usr/bin/env bash

OPENAPI_VERSION := 7.17.0
OPENAPI_CLI_URL := https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$(OPENAPI_VERSION)/openapi-generator-cli-$(OPENAPI_VERSION).jar

NETBOX_VERSION  := 4.4.8
NETBOX_LIB_DIR  := versions/netbox-client.$(NETBOX_VERSION)
NETBOX_PATCH    := versions/netbox-client.$(NETBOX_VERSION).diff
NETBOX_API_FILE := versions/netbox-rest.$(NETBOX_VERSION).yml

# This is the default task
all: help

.PHONY: all

################
# Public tasks #
################

build: generate patch format ## Install, generate, patch, format

install_open_api: ## Install OpenAPI jar
	curl $(OPENAPI_CLI_URL) --output openapi-generator-cli.jar

generate: ## Generate NetboxClient
	rm -rf ./versions/netbox-client-$(NETBOX_VERSION)
	export _JAVA_OPTIONS=-DmaxYamlCodePoints=99999999 && \
		java -jar openapi-generator-cli.jar generate \
		-g crystal \
		-i $(NETBOX_API_FILE) \
		-o $(NETBOX_LIB_DIR) \
		$(shell cat schema_mapping.txt)

patch: ## Patch NetboxClient code
	sed -i 's/: Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time/: Hash(String, Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time | Hash(String, Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time))/g' $(shell grep -rn 'type: Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time' $(NETBOX_LIB_DIR)/src/netbox-client/models | cut -d ':' -f 1 | sort | uniq)
	sed -i 's/Array(Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time)/Array(Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time | Hash(String, Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time | Hash(String, Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time)))/g' $(shell grep -rn 'Array(Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time)' $(NETBOX_LIB_DIR)/src/netbox-client/models | cut -d ':' -f 1 | sort | uniq)
	echo "ok"

format: ## Format NetboxClient code
	crystal tool format $(NETBOX_LIB_DIR)/spec
	crystal tool format $(NETBOX_LIB_DIR)/src
	crystal tool format $(NETBOX_LIB_DIR)/spec
	crystal tool format $(NETBOX_LIB_DIR)/src

.PHONY: build install_open_api generate patch format

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
