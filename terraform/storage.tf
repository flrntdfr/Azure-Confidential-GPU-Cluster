# // AZURE FILES SHARED STORAGE

/*
 * STORAGE NETWORKING
 */

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = "storage-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.cluster_subnet.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.cluster_storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  depends_on = [
    azurerm_storage_account.cluster_storage,
    azurerm_subnet.cluster_subnet
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_private_dns_zone" "storage_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
  name                  = "storage-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.cluster_vnet.id

  depends_on = [
    azurerm_private_dns_zone.storage_dns_zone,
    azurerm_virtual_network.cluster_vnet
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_private_dns_a_record" "storage_dns_record" {
  name                = "confclustersharedstorage"
  zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_private_endpoint.private_service_connection[0].private_ip_address]

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.storage_dns_link,
    azurerm_private_endpoint.storage_private_endpoint
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_storage_account" "cluster_storage" {
  name                          = "confclustersharedstorage"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Premium"
  account_kind                  = "FileStorage"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true # https://learn.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer
  public_network_access_enabled = false
  lifecycle {
    prevent_destroy = false
    create_before_destroy = true
  }
}

// Create the File Share
resource "azurerm_storage_share" "cluster_share" {
  name               = "confcluster-shared-storage-volume"
  storage_account_id = azurerm_storage_account.cluster_storage.id
  quota              = var.storage_quota_gb
  enabled_protocol   = "SMB"

  depends_on = [
    azurerm_storage_account.cluster_storage
  ]

  lifecycle {
    prevent_destroy = false
    create_before_destroy = true
  }
}