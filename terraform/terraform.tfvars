// SLURM partition configurations
// https://docs.microsoft.com/azure/confidential-computing/confidential-vm-overview

admin_username      = "slurmadmin"
location            = "westeurope"
resource_group_name = "confcluster-rg"

tee_off_config = {
  name                     = "tee-off"
  node_count               = 0                 # Set to 0 to disable partition
  node_size                = "Standard_D2ads_v5" // Dev: Standard_D2ads_v5, CPU: Standard_D4ads_v5, GPU: Standard_NC40ads_H100_v5
  storage_account_type     = "Standard_LRS"
  disk_size_gb             = 30
  use_ephemeral_disk       = false
  secure_boot_enabled      = false
  vtpm_enabled             = false
  security_encryption_type = "" # DiskWithVMGuestState"
  image_publisher          = "Canonical"
  image_offer              = "ubuntu-24_04-lts"
  image_sku                = "server"
  image_version            = "latest"
  custom_data              = ""
}

tee_on_config = {
  name                     = "tee-on"
  node_count               = 1                   # Set to 0 to disable partition
  node_size                = "Standard_NCC40ads_H100_v5" # Dev: Standard_DC2ads_v5, CPU: Standard_DC4ads_v5, GPU: Standard_NCC40ads_H100_v5
  storage_account_type     = "Standard_LRS"
  disk_size_gb             = 30
  use_ephemeral_disk       = false
  secure_boot_enabled      = true
  vtpm_enabled             = true
  security_encryption_type = "DiskWithVMGuestState"
  # Canonical:0001-com-ubuntu-confidential-vm-focal:20_04-lts-cvm
  # Canonical:0001-com-ubuntu-confidential-vm-jammy:22_04-lts-cvm
  # Canonical:ubuntu-24_04-lts:cvm
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "cvm"
  image_version   = "latest"
  custom_data     = ""
}

// Common tags # TODO
common_tags = {
  Environment = "Production"
  Project     = "SLURM Cluster"
  Provisioner = "Terraform"
}

whitelist_ip_prefix = "*"