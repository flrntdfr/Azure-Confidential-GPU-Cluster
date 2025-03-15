// https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage

// Terraform providers for Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.22.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }

  // Store tf state in Azure Storage
  backend "azurerm" {
    resource_group_name  = "confcluster-rg"
    storage_account_name = "confclustertfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  // Credentials are in pulled with `source .env`
  features {}
}