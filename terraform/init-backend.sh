#!/bin/bash

# Script to initialize Terraform backend with values from terraform.tfvars

# Extract values from terraform.tfvars
RESOURCE_GROUP=$(grep 'backend_resource_group_name' terraform.tfvars | cut -d '=' -f2 | tr -d ' "')
STORAGE_ACCOUNT=$(grep 'backend_storage_account_name' terraform.tfvars | cut -d '=' -f2 | tr -d ' "')
CONTAINER=$(grep 'backend_container_name' terraform.tfvars | cut -d '=' -f2 | tr -d ' "')
KEY=$(grep 'backend_key' terraform.tfvars | cut -d '=' -f2 | tr -d ' "')

echo "Initializing Terraform with backend configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER"
echo "  Key: $KEY"

# Initialize Terraform with backend configuration
terraform init \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$CONTAINER" \
  -backend-config="key=$KEY"

echo "Terraform initialization complete." 