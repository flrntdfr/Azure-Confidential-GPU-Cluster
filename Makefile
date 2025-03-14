# Florent Dufour
# 07.03.2025 MUC

bootstrap: 	## First time setup
	./scripts/bootstrap.sh
cluster: ## Create the cluster
	$(MAKE) -C terraform all
ssh: 	## Connect to the cluster
	$(MAKE) -C terraform ssh
destroy: 	## Destroy the cluster
	$(MAKE) -C terraform destroy
summary: 	## Summary of the cluster ()
	az resource list --resource-group confcluster-rg --output table 
	$(MAKE) -C terraform output



help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
