/*
 * SLURM PARTITION MODULE OUTPUTS
 */


output "partition_name" {
  description = "Name of the SLURM partition"
  value       = var.partition_config.name
}

output "node_count" {
  description = "Number of nodes in the partition"
  value       = var.partition_config.node_count
} 

output "node_names" {
  description = "Names of the created VMs"
  value       = azurerm_linux_virtual_machine.partition_node[*].name
}

output "node_ids" {
  description = "IDs of the created VMs"
  value       = azurerm_linux_virtual_machine.partition_node[*].id
}

output "node_private_ips" {
  description = "Private IP addresses of the created VMs"
  value       = azurerm_network_interface.partition_nic[*].private_ip_address
}

