/*
 * SLURM PARTITION MODULE
 * This module creates a set of VMs for a SLURM partition
 */

// Create network security group for partition compute nodes
resource "azurerm_network_security_group" "partition_nsg" {
  count               = var.partition_config.node_count > 0 ? 1 : 0
  name                = "confcluster-${var.partition_config.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

// Create network interfaces for each compute node
resource "azurerm_network_interface" "partition_nic" {
  count               = var.partition_config.node_count
  name                = "confcluster-${var.partition_config.name}-node-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.ip_base == "10.0.2" ? "10.0.2.${count.index + 1}" : "10.0.3.${count.index + 1}"
  }
}

// Local variables for IP addressing
locals {
  ip_base = var.partition_config.name == "tee-off" ? "10.0.2" : "10.0.3"
}

// Associate the security group with the NICs
resource "azurerm_network_interface_security_group_association" "partition_nsg_association" {
  count                     = var.partition_config.node_count
  network_interface_id      = azurerm_network_interface.partition_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.partition_nsg[0].id
}

// Create the compute nodes
resource "azurerm_linux_virtual_machine" "partition_node" {
  count               = var.partition_config.node_count
  name                = "confcluster-${var.partition_config.name}-node-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.partition_config.node_size
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.partition_nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.partition_config.storage_account_type
    disk_size_gb         = var.partition_config.disk_size_gb
    
#     // Enable ephemeral OS disk if specified
#     dynamic "diff_disk_settings" {
#       for_each = var.partition_config.use_ephemeral_disk ? [1] : []
#       content {
#         option = "Local"
#       }
#     }
   }

  source_image_reference {
    publisher = var.partition_config.image_publisher
    offer     = var.partition_config.image_offer
    sku       = var.partition_config.image_sku
    version   = var.partition_config.image_version
  }

  // Add custom data script if provided
  custom_data = var.partition_config.custom_data != "" ? base64encode(var.partition_config.custom_data) : null

  // Add tags
  tags = merge(
    var.common_tags,
    {
      "slurm_partition" = var.partition_config.name
    }
  )
} 