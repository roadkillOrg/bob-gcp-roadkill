# Data sources for subnets (referenced in address resources)
# Add your actual subnet data sources here

data "google_compute_subnetwork" "shared-private-west" {
  name    = "shared-private-west"
  region  = "us-west1"
  project = var.host_project
}

data "google_compute_subnetwork" "shared-private-east" {
  name    = "shared-private-east"
  region  = "us-east1"
  project = var.host_project
}

# Add more subnet data sources as needed for your other regions
