/*
 * SLURM LOGIN NODE
 */

// The public IP address for the login node
resource "azurerm_public_ip" "login_pip" {
  name                = "confcluster-login-node-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

// The network interface for the login node
resource "azurerm_network_interface" "login_nic" {
  name                = "confcluster-login-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cluster_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.1"
    public_ip_address_id          = azurerm_public_ip.login_pip.id
  }

  depends_on = [
    azurerm_subnet.cluster_subnet,
    azurerm_public_ip.login_pip
  ]

  lifecycle {
    create_before_destroy = true
  }
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

  security_rule {
    name                       = "Incoming-to-slurmctld"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6817"
    source_address_prefix      = var.whitelist_ip_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-NFS-Storage"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2049"
    source_address_prefix      = "*"
    destination_address_prefix = "Storage"
  }
}

// Associate the security group with the NIC
resource "azurerm_network_interface_security_group_association" "login_nsg_association" {
  network_interface_id      = azurerm_network_interface.login_nic.id
  network_security_group_id = azurerm_network_security_group.login_nsg.id

  depends_on = [
    azurerm_network_interface.login_nic,
    azurerm_network_security_group.login_nsg
  ]

  lifecycle {
    create_before_destroy = false
  }
}

// The login node
resource "azurerm_linux_virtual_machine" "login_node" {
  name                = "confcluster-login"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2s_v3" // 2 vCPUs, 8 GB RAM non burstable
  admin_username      = var.admin_username

  depends_on = [
    azurerm_network_interface_security_group_association.login_nsg_association
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.login_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # https://documentation.ubuntu.com/azure/en/latest/azure-how-to/instances/find-ubuntu-images/
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = merge(
    var.common_tags,
    {
      "node_type"     = "login"
      "environment"   = lookup(var.common_tags, "environment", "dev")
      "owner"         = lookup(var.common_tags, "owner", "research-team")
      "cost-center"   = lookup(var.common_tags, "cost-center", "research")
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      source_image_reference
    ]
  }
}

