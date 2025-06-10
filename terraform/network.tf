/*
 * NETWORKING RESOURCES
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

