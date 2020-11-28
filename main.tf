data "google_project" "current" {}

data "google_compute_default_service_account" "default" {}

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

resource "google_service_account" "default" {
  account_id   = "development"
  display_name = "Service Account for Cloud Development"
}

resource "google_compute_instance" "default" {
  name                      = var.name
  zone                      = var.zone
  tags                      = concat(list("${var.name}-ssh", var.name), var.node_tags)
  machine_type              = var.machine_type
  min_cpu_platform          = var.min_cpu_platform
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
    map("enable-oslogin", "TRUE", "startup-script", var.startup_script, "tf_depends_id", var.depends_id),
    var.metadata
  )

  service_account {
    email  = google_service_account.default.email
    scopes = var.service_account_scopes
  }
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

// IAP
module "iap_tunneling" {
  source = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"
  version = "v2.10.0"

  project                    = data.google_project.current.name
  network                    = google_compute_network.default.name
  service_accounts           = [google_service_account.default.email]

  instances = [{
    name = google_compute_instance.default.name
    zone = var.zone
  }]

  members = var.iap_members
}
