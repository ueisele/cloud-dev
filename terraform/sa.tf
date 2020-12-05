// SA and Role Bindings
resource "google_service_account" "ansible_sa" {
  account_id   = "${var.name}-ansible"
  display_name = "Service Account for ${var.name} Ansible"
}

// Account Key

resource "google_service_account_key" "ansible_sa_account_key" {
  service_account_id = google_service_account.ansible_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "ansibe_sa_account_private_key" {
    content  = base64decode(google_service_account_key.ansible_sa_account_key.private_key)
    filename = "output/account/ansible_sa_private_key.json"
    file_permission = "0400"
}

resource "local_file" "ansibe_sa_account_public_key" {
    content  = base64decode(google_service_account_key.ansible_sa_account_key.public_key)
    filename = "output/account/ansible_sa_public_key.pub"
    file_permission = "0444"
}

// SSH Key

provider "google" {
  project = var.project
  alias        = "google_ansible_sa"
  credentials = base64decode(google_service_account_key.ansible_sa_account_key.private_key)
}

resource "tls_private_key" "ansible_sa_ssh_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "google_os_login_ssh_public_key" "ansible_sa_os_login_ssh_public_key" {
  provider = google.google_ansible_sa
  user = google_service_account.ansible_sa.email
  key = tls_private_key.ansible_sa_ssh_private_key.public_key_openssh
}

resource "local_file" "ansibe_sa_ssh_private_key" {
    content  = tls_private_key.ansible_sa_ssh_private_key.private_key_pem
    filename = "output/ssh/ansible_sa_private_key.pem"
    file_permission = "0400"
}

resource "local_file" "ansibe_sa_ssh_public_key" {
    content  = tls_private_key.ansible_sa_ssh_private_key.public_key_openssh
    filename = "output/ssh/ansible_sa_public_key.pub"
    file_permission = "0444"
}

// Output

output "ansible_sa_email" {
  value = google_service_account.ansible_sa.email
}

output "ansible_sa_unique_id" {
  value = google_service_account.ansible_sa.unique_id
}

output "ansible_sa_username" {
  value = "sa_${google_service_account.ansible_sa.unique_id}"
}

output "ansible_sa_private_key_file" {
  value = abspath(local_file.ansibe_sa_ssh_private_key.filename)
}

output "ansible_sa_public_key_file" {
  value = abspath(local_file.ansibe_sa_ssh_public_key.filename)
}