/*
 * SLURM PARTITIONS
 * This file creates two SLURM partitions using the partition module
 */

// Create the TEE OFF SLURM partition
module "tee_off" {
  source = "./modules/partition"

  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh_key.public_key_openssh
  subnet_id           = azurerm_subnet.cluster_subnet.id
  common_tags         = var.common_tags
  login_node_private_ip = azurerm_network_interface.login_nic.private_ip_address
  cluster_cidr        = azurerm_subnet.cluster_subnet.address_prefixes[0]

  partition_config = var.tee_off_config

  depends_on = [
    azurerm_linux_virtual_machine.login_node,
    azurerm_subnet.cluster_subnet
  ]
}

// Create the TEE ON SLURM partition
module "tee_on" {
  source = "./modules/partition"

  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh_key.public_key_openssh
  subnet_id           = azurerm_subnet.cluster_subnet.id
  common_tags         = var.common_tags
  login_node_private_ip = azurerm_network_interface.login_nic.private_ip_address
  cluster_cidr        = azurerm_subnet.cluster_subnet.address_prefixes[0]

  partition_config = var.tee_on_config

  depends_on = [
    azurerm_linux_virtual_machine.login_node,
    azurerm_subnet.cluster_subnet
  ]
}

// Output the private IP addresses for both partitions
output "tee_off_node_private_ips" {
  value = module.tee_off.node_private_ips
}

output "tee_on_node_private_ips" {
  value = module.tee_on.node_private_ips
}

