// AZURE FILES SHARED STORAGE

resource "azurerm_storage_account" "cluster_storage" {
  name                     = "confclustersharedstorage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_kind             = "FileStorage"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = [] // TODO ?
  }
}

// Create the File Share
resource "azurerm_storage_share" "cluster_share" {
  name               = "confcluster-shared-storage-volume"
  storage_account_id = azurerm_storage_account.cluster_storage.id
  quota              = 100 // GB
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