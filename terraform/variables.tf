/* -------------- *
 * CLUSTER CONFIG *
 * -------------- */

// The cloud availability zone

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
  validation {
    condition     = contains(["westeurope", "eastus2"], var.location) # As of mid-2025
    error_message = "Invalid Azure region. Must be one of: westeurope, eastus2."
  }
}

// The cluster partitions configuration

variable "tee_off_config" {
  description = "Configuration for the TEE-OFF SLURM partition"
  type = object({
    name                     = string
    node_count               = number
    node_size                = string
    storage_account_type     = string
    disk_size_gb             = number
    use_ephemeral_disk       = bool
    secure_boot_enabled      = bool
    vtpm_enabled             = bool
    security_encryption_type = string
    image_publisher          = string
    image_offer              = string
    image_sku                = string
    image_version            = string
    custom_data              = string
  })
  default = {
    name                     = "tee-off"
    node_count               = 2
    node_size                = "Standard_NC40ads_H100_v5"
    storage_account_type     = "Standard_LRS"
    disk_size_gb             = 30
    use_ephemeral_disk       = false
    secure_boot_enabled      = true
    vtpm_enabled             = true
    security_encryption_type = ""
    image_publisher          = "Canonical"
    image_offer              = "ubuntu-24_04-lts"
    image_sku                = "server"
    image_version            = "latest"
    custom_data              = ""
  }
}

variable "tee_on_config" {
  description = "Configuration for the TEE-ON SLURM partition"
  type = object({
    name                     = string
    node_count               = number
    node_size                = string
    storage_account_type     = string
    disk_size_gb             = number
    use_ephemeral_disk       = bool
    secure_boot_enabled      = bool
    vtpm_enabled             = bool
    security_encryption_type = string
    image_publisher          = string
    image_offer              = string
    image_sku                = string
    image_version            = string
    custom_data              = string
  })
  default = {
    name                     = "tee-on"
    node_count               = 2
    node_size                = "Standard_NCC40ads_H100_v5"
    storage_account_type     = "Standard_LRS"
    disk_size_gb             = 30
    use_ephemeral_disk       = false
    secure_boot_enabled      = true
    vtpm_enabled             = true
    security_encryption_type = "DiskWithVMGuestState"
    image_publisher          = "Canonical"
    image_offer              = "ubuntu-24_04-lts"
    image_sku                = "server"
    image_version            = "latest"
    custom_data              = ""
  }
}

// The storage

variable "storage_quota_gb" {
  description = "Storage quota for the cluster"
  type        = number
  default     = 50
}

// Common tags to apply to all resources

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "SLURM Cluster"
  }
}

// SECURITY

// The source address prefix to whitelist
variable "whitelist_ip_prefix" {
  description = "source address prefix to whitelist"
  type        = string
  default     = "*" // No security
}

/* --------------- *
 * ADVANCED CONFIG *
 * --------------- */

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "confcluster-rg"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "slurmadmin"
}