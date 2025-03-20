# Makefile

TF   := terraform # terraform, tofu
PLAN := plan.tfplan

all: init plan apply ## Create the cluster with Terraform
init: ## Initialize the Terraform configuration
	$(TF) init
plan: ## Create a Terraform plan
	$(TF) plan -out=$(PLAN)
apply: ## Apply the Terraform plan
	$(TF) apply -auto-approve $(PLAN)
output: ## Print the Terraform output
	$(TF) output
ssh: ## Connect to the cluster
	ssh $(shell terraform output login_node_public_ip) -l slurmadmin -i ../private_key.pem
destroy: ## Destroy the Terraform cloud resources
	terraform apply -auto-approve -destroy
help: 	## Print this help
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'