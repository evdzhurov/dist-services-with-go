.PHONY: help
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

compile-proto: ## Compile proto files
	protoc api/v1/*.proto --go_out=. --go_opt=paths=source_relative --proto_path=.

test: ## Run tests
	go test -race ./...