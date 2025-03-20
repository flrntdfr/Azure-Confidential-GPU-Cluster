/* -------------- *
 * CLUSTER CONFIG *
 * -------------- */

// The cloud availability zone

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

// The cluster partitions configuration

variable "tee_off_config" {
  description = "Configuration for the TEE OFF SLURM partition"
  type = object({
    name                 = string
    node_count           = number
    node_size            = string
    storage_account_type = string
    disk_size_gb         = number
    use_ephemeral_disk   = bool
    secure_boot_enabled  = bool
    vtpm_enabled         = bool
    image_publisher      = string
    image_offer          = string
    image_sku            = string
    image_version        = string
    custom_data          = string
  })
  default = {
    name                 = "tee-off"
    node_count           = 2
    node_size            = "Standard_D2s_v3"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    use_ephemeral_disk   = false
    secure_boot_enabled  = true
    vtpm_enabled         = true
    image_publisher      = "Canonical"
    image_offer          = "ubuntu-24_04-lts"
    image_sku            = "server"
    image_version        = "latest"
    custom_data          = ""
  }
}

variable "tee_on_config" {
  description = "Configuration for the TEE ON SLURM partition"
  type = object({
    name                 = string
    node_count           = number
    node_size            = string
    storage_account_type = string
    disk_size_gb         = number
    use_ephemeral_disk   = bool
    secure_boot_enabled  = bool
    vtpm_enabled         = bool
    image_publisher      = string
    image_offer          = string
    image_sku            = string
    image_version        = string
    custom_data          = string
  })
  default = {
    name                 = "tee-on"
    node_count           = 2
    node_size            = "Standard_D4s_v3"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    use_ephemeral_disk   = false
    secure_boot_enabled  = true
    vtpm_enabled         = true
    image_publisher      = "Canonical"
    image_offer          = "ubuntu-24_04-lts"
    image_sku            = "server"
    image_version        = "latest"
    custom_data          = ""
  }
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