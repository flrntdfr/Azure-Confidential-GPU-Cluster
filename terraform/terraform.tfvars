location = "westeurope"

tee_on_partition_config = {
  name       = "tee-on"
  node_count = 1 # 0 to disable partition
  node_size  = "Standard_DC4s_v3"
}

tee_off_partition_config = {
  name       = "tee-off"
  node_count = 1 # 0 to disable partition
  node_size  = "Standard_D2s_v3"
}

whitelist_ip_prefix = "*"

resource_group_name = "confcluster-rg"
admin_username = "slurmadmin"