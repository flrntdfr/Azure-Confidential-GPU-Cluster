# bonjour.sh
RESOURCE_GROUP_NAME="confcluster-rg"
LOCATION="westeurope"

## Deps
#Check docker

## devcontainer
# Enter container where git, SSH, python, ansible are installed

## TERRAFORM

# Check terraform is installed (1.11.1) (https://developer.hashicorp.com/terraform/install)
# terraform version

## AZURE

# Check azure connection / azure subscription
#az account show
# Put credentials in .env
#source .env
# Create resource group
#az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
# Create action group and resource tracking

# Create key files / SSH key pair
# Create storage account for terraform state
az storage account create \
  --name "confclustertfstate" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku "Standard_LRS" \
  --allow-blob-public-access false \
  --require-infrastructure-encryption true \
  #--encryption-services "blob, file, queue, table" # TODO check for customer provided key

# Create storage container for terraform state
az storage container create \
  --name "tfstate" \
  --account-name "confclustertfstate" \
  --auth-mode login \
  --public-access "off" # TODO: Check other options