// NETWORKING RESOURCES
// Resources for the virtual network, subnets, and related components

// Virtual Network for the Cluster
resource "azurerm_virtual_network" "cluster_vnet" {
  name                = "slurm-cluster-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "production"
    role        = "slurm-cluster"
  }
}

// Subnet for Login and Compute Nodes
resource "azurerm_subnet" "cluster_subnet" {
  name                 = "slurm-cluster-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// Network Security Group for Login Node
resource "azurerm_network_security_group" "login_nsg" {
  name                = "login-node-nsg"
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
    source_address_prefix      = "*"  // Consider restricting this in production
    destination_address_prefix = "*"
  }

  tags = {
    environment = "production"
    role        = "slurm-login"
  }
} 