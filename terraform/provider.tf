// Terraform providers
terraform {
  required_providers {
    // https://registry.terraform.io/providers/hashicorp/azurerm
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.34.0"
    }
    // https://registry.terraform.io/providers/hashicorp/local
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    // https://registry.terraform.io/providers/hashicorp/tls
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }

  // Store tf state in Azure Storage
  //https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage
  backend "azurerm" {
    resource_group_name  = "confcluster-rg"
    storage_account_name = "confclustertfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  // Credentials are in pulled from .env file
  features {}
}