// VARIABLES

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "confcluster-rg"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # TODO use key generated in bootstrap.sh
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "slurmadmin"
}

