tee_off_config = {
  name                     = "tee-off"
  node_count               = 1
  node_size                = "Standard_D2ads_v5"
  storage_account_type     = "Standard_LRS"
  disk_size_gb             = 30
  use_ephemeral_disk       = false
  secure_boot_enabled      = false
  vtpm_enabled             = false
  security_encryption_type = ""
  image_publisher          = "Canonical"
  image_offer              = "ubuntu-24_04-lts"
  image_sku                = "server"
  image_version            = "latest"
  custom_data              = ""
}

tee_on_config = {
  name                     = "tee-on"
  node_count               = 1
  node_size                = "Standard_DC2ads_v5"
  storage_account_type     = "Standard_LRS"
  disk_size_gb             = 30
  use_ephemeral_disk       = false
  secure_boot_enabled      = true
  vtpm_enabled             = true
  security_encryption_type = "VMGuestStateOnly"
  image_publisher          = "Canonical"
  image_offer              = "ubuntu-24_04-lts"
  image_sku                = "cvm"
  image_version            = "latest"
  custom_data              = ""
}

storage_quota_gb = 100

common_tags = {
  Environment = "dev-cpu"
  Project     = "Confidential GPU Cluster"
  Provisioner = "Terraform"
}