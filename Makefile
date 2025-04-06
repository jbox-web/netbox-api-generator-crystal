# Ensure that every command in this Makefile
# will run with bash instead of the default sh
SHELL := /usr/bin/env bash

NETBOX_VERSION  := 4.2.7
OPENAPI_VERSION := 7.17.0

# This is the default task
all: help

.PHONY: all

################
# Public tasks #
################

build: install_open_api generate format ## Install, generate, format

install_open_api: ## Install OpenAPI jar
	wget https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$(OPENAPI_VERSION)/openapi-generator-cli-$(OPENAPI_VERSION).jar -O openapi-generator-cli.jar

generate: ## Generate NetboxClient
	rm -rf ./versions/netbox-client-$(NETBOX_VERSION)
	export _JAVA_OPTIONS=-DmaxYamlCodePoints=99999999 && \
		java -jar openapi-generator-cli.jar generate \
		-i ./versions/netbox-rest.$(NETBOX_VERSION).yml \
		-g crystal \
		-o ./versions/netbox-client-$(NETBOX_VERSION) \
		--additional-properties moduleName=NetboxClient \
		--additional-properties shardName=netbox-client \
		--type-mappings "Object=Nil | String | Bool | Int32 | Int64 | Float32 | Float64 | Time"

format: ## Format NetboxClient code
	crystal tool format ./versions/netbox-client-$(NETBOX_VERSION)/spec
	crystal tool format ./versions/netbox-client-$(NETBOX_VERSION)/src

.PHONY: build install_open_api generate format

#################
# Private tasks #
#################

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
