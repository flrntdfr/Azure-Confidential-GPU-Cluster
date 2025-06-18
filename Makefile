# Florent Dufour
# 2025 - MUC

SHELL             := /bin/bash
AZ_RESOURCE_GROUP := confcluster-rg
AZ_LOCATION       := westeurope

.PHONY: login bootstrap unbootstrap cluster-dev-cpu cluster-dev-gpu ssh summary ansible destroy help

# ----- #
# AZURE #
# ----- #

login: ## Login to Azure
	@az login
	@echo "# Use \`make login\` to populate this file" > .env
	@-echo "export ARM_SUBSCRIPTION_ID=\"$(shell az account show --query id --output tsv)\"" >> .env
	@-echo "export ARM_TENANT_ID=\"$(shell az account show --query tenantId --output tsv)\"" >> .env
	@echo -e "You can now:\nsource .env\n\nYou should then: \nmake bootstrap"
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
unbootstrap: destroy ## Unbootstrap Azure backend and destroy the cluster
	az storage container delete --name "tfstate" --account-name "confclustertfstate"
	az storage account delete --name "confclustertfstate" --resource-group $(AZ_RESOURCE_GROUP)

# ------- #
# CLUSTER #
# ------- #

cluster: cluster-gpu-prod ## Create default cluster with GPUs (eq. gpu-prod)
cluster-cpu-dev: ## Create dev cluster with CPUs
	$(MAKE) -C terraform VAR_FILE=environments/dev-cpu.tfvars all
	$(MAKE) -C ansible all
cluster-gpu-dev: ## Create dev cluster with GPUs
	$(MAKE) -C terraform VAR_FILE=environments/dev-gpu.tfvars all
	$(MAKE) -C ansible all
cluster-gpu-prod: ## Create prod cluster with GPUs
	$(MAKE) -C terraform VAR_FILE=environments/prod-gpu.tfvars all
	$(MAKE) -C ansible all
ssh: 	## Connect to the running cluster
	-$(MAKE) -C terraform ssh
summary: ## Get summary resources running in the cloud
	az resource list --resource-group confcluster-rg --output table 
	$(MAKE) -C terraform output
destroy: 	## Destroy the cluster
	$(MAKE) -C terraform destroy

# ------- #
# UTILITY #
# ------- #

ansible:
	$(MAKE) -C ansible all
help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
