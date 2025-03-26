/*
 * SLURM PARTITION MODULE VARIABLES
 */

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
  validation {
    condition     = contains(["westeurope", "eastus2"], var.location)
    error_message = "Invalid Azure region. Please use 'westeurope' or 'eastus2'."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where VMs will be created"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "partition_config" {
  description = "Configuration for the SLURM partition"
  type = object({
    name                = string
    node_count          = number
    node_size           = string
    storage_account_type = string
    disk_size_gb        = number
    use_ephemeral_disk  = bool
    secure_boot_enabled = bool
    vtpm_enabled        = bool
    security_encryption_type = string
    image_publisher     = string
    image_offer         = string
    image_sku           = string
    image_version       = string
    custom_data         = string
  })
} 