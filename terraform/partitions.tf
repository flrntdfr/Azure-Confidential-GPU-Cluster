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

  partition_config = var.tee_off_config

  depends_on = [
    azurerm_storage_account.cluster_storage,
    azurerm_storage_share.cluster_share
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

  partition_config = var.tee_on_config

  depends_on = [
    azurerm_storage_account.cluster_storage,
    azurerm_storage_share.cluster_share
  ]
}

// Output the private IP addresses for both partitions
output "tee_off_node_private_ips" {
  value = module.tee_off.node_private_ips
}

output "tee_on_node_private_ips" {
  value = module.tee_on.node_private_ips
} 

