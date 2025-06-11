
# Florent Dufour
# MUC 03.2025

SHELL             := /bin/bash
AZ_RESOURCE_GROUP := confcluster-rg
AZ_LOCATION       := westeurope

.PHONY: login bootstrap cluster destroy unbootstrap ssh summary terraform ansible

login: ## Login to Azure
	az login
	-@echo "# Use \`make login\` to populate this file" > .env
	-@echo "export ARM_SUBSCRIPTION_ID=\"$(shell az account show --query id --output tsv)\"" >> .env
	-@echo "export ARM_TENANT_ID=\"$(shell az account show --query tenantId --output tsv)\"" >> .env
	-@source terraform/.env # FIXME
	@echo "You can now \`source terraform/.env\` then \`make bootstrap\` to bootstrap environment"
bootstrap: login source ## First time setup Azure backend
	az storage account create \
		--name "confclustertfstate" \
		--resource-group $(AZ_RESOURCE_GROUP) \
		--location $(AZ_LOCATION) \
		--sku "Standard_LRS" \
		--allow-blob-public-access false \
		--require-infrastructure-encryption true
	az storage container create \
		--name "tfstate" \
		--account-name "confclustertfstate" \
		--auth-mode login \
		--public-access "off" 
	@echo "You can now \`make cluster\` to create the cluster"

cluster: terraform ansible ## Create and connect to the cluster
destroy: 	## Destroy the cluster
	$(MAKE) -C terraform destroy
make unbootstrap: destroy ## Destroy the cluster and bootstrap resources
	# TODO: Implement unbootstrap

# ------- #
# UTILITY #
# ------- #

ssh: 	## Connect to the running cluster
	-$(MAKE) -C terraform ssh
summary: 	## Get summary resources running in the cloud
	az resource list --resource-group confcluster-rg --output table 
	$(MAKE) -C terraform output
terraform: ## (Only terraform the cluster)
	$(MAKE) -C terraform all
ansible: ## (Only configure the cluster)
	$(MAKE) -C ansible all
help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


test:
	@export PROUT=ROUTPTUFGSDFG