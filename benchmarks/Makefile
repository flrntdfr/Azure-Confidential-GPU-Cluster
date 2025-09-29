# Benchmarks


.PHONY: all finetuning inference resume-cluster help

all: 	## Run all benchmarks
	@find . -name "*.slurm" -exec sbatch {} \;
finetuning: 	## Run finetuning benchmarks
	@find . -name "finetuning-*.slurm" -exec sbatch {} \;
inference: 	## Run inference benchmarks
	@find . -name "inference-*.slurm" -exec sbatch {} \;
resume-cluster: 	## Resume the cluster
	sudo scontrol update NodeName=confcluster-tee-on-1 State=RESUME # FIXME all nodes


help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'