# Makefile for inference benchmarks

bootstrap: ## Bootstrap environment
	./bootstrap.sh
benchmark: ## Run all experiments
	./submit_experiments.py
collect: ## Collect results in a single place
	mv results /persistent # FIXME
help: ## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'