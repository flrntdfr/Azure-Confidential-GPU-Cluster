# Makefile for finetuning benchmarks

.PHONY: bootstrap benchmark zip help

all: bootstrap benchmark

bootstrap: ## Bootstrap environment
	./bootstrap.sh
benchmark: ## Run all experiments
	-@find . -name "src/*.sbatch" -exec sbatch {} \;
zip: ## Collect results in a single place
	tar -cJvf /persistent/$(date +%Y%m%d_%H%M-%S)-results-finetuning.txz results
help: ## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'