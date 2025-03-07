# Florent Dufour
# 07.03.2025 MUC

bonjour: 	## First time setup
	./scripts/bonjour.sh

cluster: 	## Create the cluster

ssh: 	## Connect to the cluster

destroy: 	## Destroy the cluster
	terraform destroy

tschüss: 	## Destroy the cluster and start from scratch
	./scripts/tschüss.sh

help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

