admin_username = "slurmadmin"

// SLURM partition configurations
tee_off_config = {
  name                 = "tee-off"
  node_count           = 1 # Set to 0 to disable partition
  node_size            = "Standard_D2s_v3"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 30
  use_ephemeral_disk   = false
  image_publisher      = "Canonical"
  image_offer          = "ubuntu-24_04-lts"
  image_sku            = "server"
  image_version        = "latest"
  custom_data          = ""
}

tee_on_config = {
  name                 = "tee-on"
  node_count           = 1 # Set to 0 to disable partition
  node_size            = "Standard_D2s_v3"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 30
  use_ephemeral_disk   = false
  image_publisher      = "Canonical"
  image_offer          = "ubuntu-24_04-lts"
  image_sku            = "server"
  image_version        = "latest"
  custom_data          = ""
}

// Common tags # TODO
common_tags = {
  Environment = "Production"
  Project     = "SLURM Cluster"
  Provisioner = "Terraform"
}

whitelist_ip_prefix = "*"

location            = "westeurope"
resource_group_name = "confcluster-rg"