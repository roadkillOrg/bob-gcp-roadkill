# This demonstrates the solution to Nate's problem:
# - How to reference google_compute_address resources in for_each loop
# - Avoids hardcoded IP strings in locals
# - Maintains named keys for terraform taint targeting
# - Preserves the "null coalescing" pattern for optional fields

locals {
  # VM configurations WITHOUT hardcoded IP addresses
  # The IPs will be referenced from google_compute_address resources
  vms = {
    "gcp-ns-lv01" = {
      zone           = "us-west1-c"
      private_subnet = "shared-private-west"
      allow_stop     = false
      delete_protect = true
      machine_type   = null  # Will use var.ce_machine_type
      image          = null  # Will use default
      vol_type       = null
      disk_size      = null
    }
    "gcp-ns-lv02" = {
      zone           = "us-west1-b"
      private_subnet = "shared-private-west"
      allow_stop     = false
      delete_protect = true
      machine_type   = null
      image          = null
      vol_type       = null
      disk_size      = null
    }
    "gcp-ns-lv03" = {
      zone           = "us-east1-b"
      private_subnet = "shared-private-east"
      allow_stop     = false
      delete_protect = true
      machine_type   = "n1-standard-2"  # Override default
      image          = null
      vol_type       = null
      disk_size      = 50  # Override default
    }
  }

  # Address configurations - separate from VM configs
  # This includes the actual IP addresses you need to preserve
  addresses = {
    "gcp-ns-lv01" = {
      region     = "us-west1"
      subnet     = "shared-private-west"
      int_ip     = "10.20.40.18"
      ext_ip     = "35.230.55.88"
    }
    "gcp-ns-lv02" = {
      region     = "us-west1"
      subnet     = "shared-private-west"
      int_ip     = "10.20.40.19"
      ext_ip     = "35.230.55.89"
    }
    "gcp-ns-lv03" = {
      region     = "us-east1"
      subnet     = "shared-private-east"
      int_ip     = "10.30.40.18"
      ext_ip     = "34.75.100.50"
    }
  }
}

# Create INTERNAL addresses using for_each
# These replace your individual google_compute_address.lv01-int resources
resource "google_compute_address" "internal" {
  for_each = local.addresses

  name         = "${each.key}-internal"
  address_type = "INTERNAL"
  region       = each.value.region
  address      = each.value.int_ip
  purpose      = "GCE_ENDPOINT"
  subnetwork   = data.google_compute_subnetwork[each.value.subnet].id
}

# Create EXTERNAL addresses using for_each
# These replace your individual google_compute_address.lv01-ext resources
resource "google_compute_address" "external" {
  for_each = local.addresses

  name         = "${each.key}-external"
  address_type = "EXTERNAL"
  region       = each.value.region
  address      = each.value.ext_ip
}

# Create instances, referencing the addresses created above
# THE KEY: Use google_compute_address.internal[each.key].address
resource "google_compute_instance" "default" {
  for_each = local.vms

  name         = each.key
  # The "foo == null ? bar : foo" pattern you like for optional fields
  machine_type = each.value.machine_type == null ? var.ce_machine_type : each.value.machine_type
  zone         = each.value.zone
  project      = var.project
  hostname     = "${each.key}.roadkill.org"

  allow_stopping_for_update = each.value.allow_stop
  deletion_protection       = each.value.delete_protect

  boot_disk {
    initialize_params {
      image = each.value.image == null ? "debian-cloud/debian-11" : each.value.image
      size  = each.value.disk_size == null ? 10 : each.value.disk_size
      type  = each.value.vol_type == null ? "pd-standard" : each.value.vol_type
    }
  }

  network_interface {
    nic_type           = "GVNIC"
    subnetwork_project = var.host_project
    subnetwork         = each.value.private_subnet

    # HERE'S THE SOLUTION: Reference the address resource using [each.key]
    # Instead of hardcoding: network_ip = "10.20.40.18"
    network_ip = google_compute_address.internal[each.key].address

    access_config {
      # Instead of hardcoding: nat_ip = "35.230.55.88"
      nat_ip = google_compute_address.external[each.key].address
    }
  }

  metadata = {
    managed_by = "terraform"
  }
}
