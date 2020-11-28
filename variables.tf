variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "network_cidr" {
  default = "10.127.0.0/20"
}

variable "network_name" {
  default = "cloud-dev"
}

variable "machine_type" {
  description = "The type of the instance"
  default     = "e2-standard-4"
}

variable "min_cpu_platform" {
  description = "Specifies a minimum CPU platform for the VM instance. Applicable values are the friendly names of CPU platforms, such as Intel Haswell or Intel Skylake. https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform"
  default     = "Automatic"
}

variable "name" {
  description = "Name prefix for the nodes"
  default     = "cloud-dev"
}

variable "image_family" {
  default = "debian-10"
}

variable "image_project" {
  default = "debian-cloud"
}

variable "disk_auto_delete" {
  description = "Whether or not the disk should be auto-deleted."
  default     = true
}

variable "disk_type" {
  description = "The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard."
  default     = "pd-ssd"
}

variable "disk_size_gb" {
  description = "The size of the image in gigabytes."
  default     = 10
}

variable "network_ip" {
  description = "Set the network IP of the instance. Useful only when num_nodes is equal to 1."
  default     = ""
}

variable "node_tags" {
  description = "Additional compute instance network tags for the nodes."
  type        = list
  default     = []
}

variable "startup_script" {
  description = "Content of startup-script metadata passed to the instance template."
  default     = ":"
}

variable "metadata" {
  description = "Map of metadata values to pass to instances."
  type        = map
  default     = {}
}

variable "depends_id" {
  description = "The ID of a resource that the instance group depends on."
  default     = ""
}

variable "service_account_scopes" {
  description = "List of scopes for the instance template service account"
  type        = list

  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}

variable "iap_members" {
  description = "List of IAM resources to allow using the IAP tunnel."
  type        = list
  default     = []
}
