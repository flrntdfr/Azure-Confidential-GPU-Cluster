all: 	## Run all benchmarks
	@for script in $(shell ls *.slurm); do sbatch $$script; done

resume-cluster: 	## Resume the cluster

help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'