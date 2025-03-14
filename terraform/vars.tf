/*
 * VARIABLES
 */

// TODO: Make sure vars stay in sync with bootstrap.sh

// -----------
// USER

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "partitions" {
  description = "List of partitions to create"
  type        = list(string)
  default     = ["TEE-ON", "TEE-OFF"]
}

variable "whitelist_ip_prefix" {
  description = "source address prefix to whitelist"
  type        = string
  default     = "*" // No security
}

// -----------
// SYSTEM

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