/*
 * SLURM PARTITION WITH TEE OFF VMS
 */

// Create network security group for TEE OFF compute nodes
resource "azurerm_network_security_group" "tee_off_nsg" {
  count               = var.tee_off_partition_config.node_count > 0 ? 1 : 0
  name                = "confcluster-${var.tee_off_partition_config.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

// Create network interfaces for each compute node
resource "azurerm_network_interface" "tee_off_nic" {
  count               = var.tee_off_partition_config.node_count
  name                = "confcluster-${var.tee_off_partition_config.name}-node-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cluster_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

// Associate the security group with the NICs
resource "azurerm_network_interface_security_group_association" "tee_off_nsg_association" {
  count                     = var.tee_off_partition_config.node_count
  network_interface_id      = azurerm_network_interface.tee_off_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.tee_off_nsg[0].id
}

// Create the compute nodes with standard (non-TEE) configuration
resource "azurerm_linux_virtual_machine" "tee_off_node" {
  count               = var.tee_off_partition_config.node_count
  name                = "confcluster-${var.tee_off_partition_config.name}-node-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.tee_off_partition_config.node_size
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.tee_off_nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    #caching              = "ReadOnly" // TODO?
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    
    // Enable ephemeral OS disk
    # diff_disk_settings {
    #   option = "Local"
    # }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  depends_on = [
    azurerm_storage_account.cluster_storage,
    azurerm_storage_share.cluster_share
  ]
}

// Output the private IP addresses for the TEE OFF nodes
output "tee_off_node_private_ips" {
  value = var.tee_off_partition_config.node_count > 0 ? azurerm_network_interface.tee_off_nic[*].private_ip_address : []
}
