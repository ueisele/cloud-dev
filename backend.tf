terraform {
  backend "gcs" {
    bucket     = "gcp-uweeisele-dev-terraform"
    prefix     = "cloud-dev/state"
  }
}
