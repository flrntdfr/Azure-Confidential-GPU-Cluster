# Makefile for vLLM inference benchmarks

bootstrap: ## Bootstrap vLLM
	./bootstrap.sh
serve: ## Run server with settings.sh
	./serve.sh
bench: ## Run benchmark with settings.sh
	./bench.sh
help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'