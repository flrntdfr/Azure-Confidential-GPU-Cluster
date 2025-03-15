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

variable "tee_on_partition_config" {
  description = "Configuration for TEE ON partition"
  type = object({
    name       = string
    node_count = number
    node_size  = string
  })
  default = {
    name       = "tee-on"
    node_count = 10
    node_size  = "Standard_DC2s_v3" # FIXME
  }
}

variable "tee_off_partition_config" {
  description = "Configuration for TEE OFF partition"
  type = object({
    name       = string
    node_count = number
    node_size  = string
  })
  default = {
    name       = "tee-off"
    node_count = 10
    node_size  = "Standard_D2s_v3" # FIXME
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
  default     = "slurmadmin" # TODO will break `make ssh` 
}