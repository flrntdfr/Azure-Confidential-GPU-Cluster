/*
 * SSH key pair 
 */

# The SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to file
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/../slurmadmin.pem"
  file_permission = "0600"
}

# Save public key to file
resource "local_file" "public_key_pem" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.root}/../slurmadmin.pem.pub"
  file_permission = "0644"
}
