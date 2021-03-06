// Network

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = var.network_cidr
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

// Instance

resource "google_compute_instance" "default" {
  name                      = var.name
  zone                      = var.zone
  tags                      = concat(list("${var.name}-allow-direct-ssh", var.name), var.node_tags)
  machine_type              = var.machine_type
  allow_stopping_for_update = true

  boot_disk {
    auto_delete = var.disk_auto_delete

    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork    = google_compute_subnetwork.default.name
    network_ip    = var.network_ip
    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  metadata = merge(
    map(
        "enable-oslogin", "TRUE",
        "block-project-ssh-keys", "TRUE",
        "startup-script", var.startup_script, 
        "tf_depends_id", var.depends_id
    ),
    var.metadata
  )

}

// OS Login IAM

resource "google_compute_instance_iam_binding" "member_binding_osadminlogin" {
  zone = var.zone
  instance_name = google_compute_instance.default.name
  role = "roles/compute.osAdminLogin"
  members = concat(list("serviceAccount:${google_service_account.ansible_sa.email}"), var.members_osadminlogin)
}

// DNS

data "google_dns_managed_zone" "public_dns_zone" {
  count = var.public_dns_zone != "" ? 1 : 0
  
  name  = var.public_dns_zone
}

resource "google_dns_record_set" "public_instance_dns_a_record" {
  count = length(data.google_dns_managed_zone.public_dns_zone) > 0 ? 1 : 0

  name = "${google_compute_instance.default.name}.${google_compute_network.default.name}.${data.google_dns_managed_zone.public_dns_zone[0].dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.public_dns_zone[0].name

  rrdatas = [google_compute_instance.default.network_interface.0.access_config.0.nat_ip]
}

// NAT gateway

resource "google_compute_router" "default" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.default.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "default" {
  name                               = "${var.name}-router-nat"
  router                             = google_compute_router.default.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

// SSH Access Firewall Rule

resource "google_compute_firewall" "allow_direct_ssh_to_instances" {
  name    = "allow-direct-ssh-to-instances"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.name}-allow-direct-ssh"]
}

// Output

output "instance_external_ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}

output "public_instance_fqdn" {
  value = length(data.google_dns_managed_zone.public_dns_zone) > 0 ? google_dns_record_set.public_instance_dns_a_record[0].name : ""
}

output "ssh_command_ansible_sa" {
  value = "ssh -i ${abspath(local_file.ansibe_sa_ssh_private_key.filename)} sa_${google_service_account.ansible_sa.unique_id}@${length(data.google_dns_managed_zone.public_dns_zone) > 0 ? google_dns_record_set.public_instance_dns_a_record[0].name : google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}