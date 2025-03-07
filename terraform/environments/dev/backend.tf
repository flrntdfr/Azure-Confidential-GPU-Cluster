// https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage

// PROVIDER
// Terraform provider for Azure

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }

    backend "azurerm" {
        resource_group_name  = "confcluster-rg"
        storage_account_name = "confclustertfstate"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}

provider "azurerm" {
  // Credentials are in pulled from .env
  features {}
}