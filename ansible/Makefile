# Florent Dufour
# MUC 03.2025

all: site ## End-to-end configure the cluster
site: ## Run the playbook
	ansible-playbook site.yaml -i inventory.yml
help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'