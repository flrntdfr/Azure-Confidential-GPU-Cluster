# Makefile for inference benchmarks

all: bootstrap benchmark
bootstrap: ## Bootstrap environment
	./bootstrap.sh
bench: ## Run all experiments
	-@find . -name "experiment-*.sh" -exec sbatch {} \;
collect: ## Collect results in a single place
	tar -cJvf /persistent/$(shell date +%Y%m%d_%H%M-%S)-results-inference.txz results
help: ## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'