/*
 * COMPUTE NETWORKING
 */

// The cluster virtual network
resource "azurerm_virtual_network" "cluster_vnet" {
  name                = "confcluster-net-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

// The cluster subnet (shared by all nodes)
resource "azurerm_subnet" "cluster_subnet" {
  name                 = "confcluster-net-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  address_prefixes     = ["10.0.0.0/16"]
  depends_on           = [azurerm_virtual_network.cluster_vnet]
}

/*
 * STORAGE NETWORKING
 * */

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = "storage-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.cluster_subnet.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.cluster_storage.id
    is_manual_connection           = false
    subresource_names             = ["file"]
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
}

resource "azurerm_private_dns_a_record" "storage_dns_record" {
  name                = "confclustersharedstorage"
  zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_private_endpoint.private_service_connection[0].private_ip_address]
}