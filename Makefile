# Florent Dufour
# 07.03.2025 MUC

RESOURCE_GROUP_NAME := confcluster-rg
LOCATION            := westeurope

bootstrap: 	## First time setup
	-source .env
	-az login
	-az storage account create \
		--name "confclustertfstate" \
		--resource-group $(RESOURCE_GROUP_NAME) \
		--location $(LOCATION) \
		--sku "Standard_LRS" \
		--allow-blob-public-access false \
		--require-infrastructure-encryption true
	-az storage container create \
		--name "tfstate" \
		--account-name "confclustertfstate" \
		--auth-mode login \
		--public-access "off" 
cluster: ## Create and enter the cluster
	$(MAKE) -C terraform all
	$(MAKE) ssh
ssh: 	## Connect to the cluster
	$(MAKE) -C terraform ssh
destroy: 	## Destroy the cluster
	$(MAKE) -C terraform destroy
summary: 	## Summary of the cluster
	az resource list --resource-group confcluster-rg --output table 
	$(MAKE) -C terraform output



help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
