# Makefile for inference benchmarks

all: bootstrap benchmark
bootstrap: ## Bootstrap environment
	./bootstrap.sh
benchmark: ## Run all experiments
	sbatch experiment-*
collect: ## Collect results in a single place
	tar -czvf /persistent/$(date +%Y%m%d_%H%M-%S)-results-inference.tar.gz results
help: ## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'