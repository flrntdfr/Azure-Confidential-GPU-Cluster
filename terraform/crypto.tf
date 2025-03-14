/*
 * SSH key pair 
 */

# The SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Output public key for reference
output "ssh_public_key" {
  value     = tls_private_key.ssh_key.public_key_openssh
  sensitive = true
}

# Output private key for reference
output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Save private key to file
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/../private_key.pem"
  file_permission = "0600"  # Secure permissions for private key
}
