.PHONY: help
.DEFAULT_GOAL := help

CONFIG_PATH=${HOME}/.proglog/

.PHONY: init
init:
		mkdir -p ${CONFIG_PATH}

.PHONY: gencert
gencert: ## Generate TLS certificates
		cfssl gencert \
				-initca test/ca-csr.json | cfssljson -bare ca

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=server \
				test/server-csr.json | cfssljson -bare server

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=client \
				-cn="root" \
				test/client-csr.json | cfssljson -bare root-client

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=client \
				-cn="nobody" \
				test/client-csr.json | cfssljson -bare nobody-client
		
		mv *.pem *.csr ${CONFIG_PATH}

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: compile-proto
compile-proto: ## Compile proto files
	protoc api/v1/*.proto \
		--go_out=. \
		--go-grpc_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_opt=paths=source_relative \
		--proto_path=.

$(CONFIG_PATH)/model.conf:
	cp test/model.conf $(CONFIG_PATH)/model.conf

$(CONFIG_PATH)/policy.csv:
	cp test/policy.csv $(CONFIG_PATH)/policy.csv

.PHONY: test
test: $(CONFIG_PATH)/policy.csv $(CONFIG_PATH)/model.conf ## Run tests
	go test -race ./...