// ---------- //
// LOGIN NODE //
// ---------- //

// Output the public IP address for easy access
output "login_node_public_ip" {
  value = azurerm_public_ip.login_pip.ip_address
}

// Output the login node's private IP address
output "login_node_private_ip" {
  value = azurerm_network_interface.login_nic.private_ip_address
}

// -------------- //
// SHARED STORAGE //
// -------------- //

// Output the storage account name for compute nodes
output "storage_account_name" {
  value = azurerm_storage_account.cluster_storage.name
}

// Output the file share name for compute nodes
output "file_share_name" {
  value = azurerm_storage_share.cluster_share.name
}

// Output the storage account primary access key (sensitive)
output "storage_account_key" {
  value     = azurerm_storage_account.cluster_storage.primary_access_key
  sensitive = true
} 

// ----------------- //
// ANSIBLE INVENTORY //
// ----------------- //

resource "local_file" "ansible_inventory" {
  filename = "${path.root}/../ansible/inventory.yml"
  content  = yamlencode({
    all = {
      vars = {
        public_login_ip                = azurerm_public_ip.login_pip.ip_address
        admin_username                 = var.admin_username
        ansible_ssh_private_key_file   = local_file.private_key_pem.filename
      }
      children = {
        login = {
          hosts = {
            "login_node" = {
              ansible_host = azurerm_public_ip.login_pip.ip_address
              ansible_user = var.admin_username
            }
          }
        }
        tee_off = {
          hosts = {
            for idx, ip in module.tee_off.node_private_ips : "tee_off_${idx + 1}" => {
              ansible_host            = ip
              ansible_ssh_common_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -i {{ ansible_ssh_private_key_file }} -W %h:%p {{ admin_username }}@{{ public_login_ip }}'"
              ansible_user            = "{{ admin_username }}"
            }
          }
        }
        tee_on = {
          hosts = {
            for idx, ip in module.tee_on.node_private_ips : "tee_on_${idx + 1}" => {
              ansible_host            = ip
              ansible_ssh_common_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -i {{ ansible_ssh_private_key_file }} -W %h:%p {{ admin_username }}@{{ public_login_ip }}'"
              ansible_user            = "{{ admin_username }}"
            }
          }
        }
        compute = {
          children = {
            tee_off = {}
            tee_on  = {}
          }
        }
      }
    }
  })
}