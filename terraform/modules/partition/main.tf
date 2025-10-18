/*
 * SLURM PARTITION MODULE
 * This module creates defines node configuration for a homogeneous SLURM partition
 * https://github.com/Azure/terraform/blob/master/quickstart/201-confidential-vm/main.tf
 */

// Create network security group for partition compute nodes
resource "azurerm_network_security_group" "partition_nsg" {
  count               = var.partition_config.node_count > 0 ? 1 : 0
  name                = "confcluster-${var.partition_config.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  // Allow SSH from login node only
  security_rule {
    name                       = "SSH-from-login"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.login_node_private_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Incoming-to-slurmd"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6818"
    source_address_prefix      = var.cluster_cidr
    destination_address_prefix = "*"
  }

  // Allow SLURM communication between nodes (all ports)
  security_rule {
    name                       = "SLURM-internal"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.cluster_cidr
    destination_address_prefix = "*"
  }

  // Allow outbound communication to all cluster nodes
  security_rule {
    name                       = "SLURM-outbound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.cluster_cidr
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

  lifecycle {
    create_before_destroy = true
  }
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
  count                     = var.partition_config.node_count > 0 ? var.partition_config.node_count : 0
  network_interface_id      = azurerm_network_interface.partition_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.partition_nsg[0].id

  depends_on = [
    azurerm_network_interface.partition_nic,
    azurerm_network_security_group.partition_nsg
  ]

  lifecycle {
    create_before_destroy = false
  }
}

// Create the compute nodes
resource "azurerm_linux_virtual_machine" "partition_node" {
  count               = var.partition_config.node_count
  name                = "confcluster-${var.partition_config.name}-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.partition_config.node_size
  admin_username      = var.admin_username

  depends_on = [
    azurerm_network_interface_security_group_association.partition_nsg_association
  ]

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
    security_encryption_type = var.partition_config.security_encryption_type != "" ? var.partition_config.security_encryption_type : null
   }

  source_image_reference {
    publisher = var.partition_config.image_publisher
    offer     = var.partition_config.image_offer
    sku       = var.partition_config.image_sku
    version   = var.partition_config.image_version
  }
  
  // Confidential computing stuff
  # az vm create ... --security-type ConfidentialVM ?
  vtpm_enabled        = var.partition_config.vtpm_enabled
  secure_boot_enabled = var.partition_config.secure_boot_enabled

  // Add custom data script if provided
  custom_data = var.partition_config.custom_data != "" ? base64encode(var.partition_config.custom_data) : null

  // Add tags
  tags = merge(
    var.common_tags,
    {
      "slurm_partition" = var.partition_config.name
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      custom_data
    ]
  }
} 