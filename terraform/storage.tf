// AZURE FILES SHARED STORAGE

resource "azurerm_storage_account" "cluster_storage" {
  name                          = "confclustersharedstorage"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Premium"
  account_kind                  = "FileStorage"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = false # https://learn.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer
  public_network_access_enabled = false
  lifecycle {
    prevent_destroy = true
  }
}

// Create the File Share
resource "azurerm_storage_share" "cluster_share" {
  name               = "confcluster-shared-storage-volume"
  storage_account_id = azurerm_storage_account.cluster_storage.id
  quota              = var.storage_quota_gb
  enabled_protocol   = "NFS"
  lifecycle {
    prevent_destroy = true
  }
}