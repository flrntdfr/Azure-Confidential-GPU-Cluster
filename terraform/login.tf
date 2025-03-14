// SLURM LOGIN NODE
// Resources for the SLURM login/controller node

// Public IP for Login Node
resource "azurerm_public_ip" "login_pip" {
  name                = "login-node-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "production"
    role        = "slurm-login"
  }
}

// Network Interface for Login Node
resource "azurerm_network_interface" "login_nic" {
  name                = "login-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cluster_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.login_pip.id
  }

  tags = {
    environment = "production"
    role        = "slurm-login"
  }
}

// Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "login_nsg_association" {
  network_interface_id      = azurerm_network_interface.login_nic.id
  network_security_group_id = azurerm_network_security_group.login_nsg.id
}

// Linux VM for Login Node (Budget-friendly B2s size)
resource "azurerm_linux_virtual_machine" "login_node" {
  name                = "slurm-login-node"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s"  // 2 vCPUs, 4 GB RAM - budget friendly
  admin_username      = var.admin_username
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }
  
  network_interface_ids = [
    azurerm_network_interface.login_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  // Using standard storage to save costs
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "production"
    role        = "slurm-login"
  }
  
  # Storage account keys must be retrieved after the storage account has been created
  depends_on = [
    azurerm_storage_account.cluster_storage,
    azurerm_storage_share.cluster_share
  ]
}

// Output the public IP address for easy access
output "login_node_public_ip" {
  value = azurerm_public_ip.login_pip.ip_address
}

// Output the login node's private IP address
output "login_node_private_ip" {
  value = azurerm_network_interface.login_nic.private_ip_address
}
