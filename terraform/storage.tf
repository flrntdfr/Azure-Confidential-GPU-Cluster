// AZURE FILES SHARED STORAGE
// Resources for shared storage using Azure Files Premium

// Generate a random suffix for globally unique storage account name
resource "random_string" "storage_account_suffix" {
  length  = 8
  special = false
  upper   = false
}

// Premium Storage Account for Shared File System
resource "azurerm_storage_account" "cluster_storage" {
  name                     = "slurmcluster${random_string.storage_account_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_kind             = "FileStorage"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  network_rules {
    default_action = "Allow"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }

  tags = {
    environment = "production"
    role        = "slurm-shared-storage"
  }
}

// Create the File Share
resource "azurerm_storage_share" "cluster_share" {
  name                 = "slurmshare"
  storage_account_name = azurerm_storage_account.cluster_storage.name
  quota                = 100  // GB
}

// Output the storage account name for compute nodes
output "storage_account_name" {
  value = azurerm_storage_account.cluster_storage.name
}

// Output the file share name for compute nodes
output "file_share_name" {
  value = azurerm_storage_share.cluster_share.name
}

// Output the storage account primary access key (sensitive)
output "storage_account_key" {
  value     = azurerm_storage_account.cluster_storage.primary_access_key
  sensitive = true
} 