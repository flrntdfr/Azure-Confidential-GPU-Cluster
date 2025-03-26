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