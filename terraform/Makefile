all: init plan apply

init:
	terraform init

plan:
	terraform plan -out=plan.tfplan

apply:
	terraform apply -auto-approve plan.tfplan

destroy:
	terraform destroy