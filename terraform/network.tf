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

// The cluster subnet
resource "azurerm_subnet" "cluster_subnet" {
  name                 = "confcluster-net-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// The network security group for the login node
resource "azurerm_network_security_group" "login_nsg" {
  name                = "confcluster-login-node-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.whitelist_ip_prefix
    destination_address_prefix = "*"
  }
} 