output "instances" {
  description = "Instance details showing both internal and external IPs"
  value = {
    for k, v in google_compute_instance.default : k => {
      name        = v.name
      hostname    = v.hostname
      zone        = v.zone
      internal_ip = google_compute_address.internal[k].address
      external_ip = google_compute_address.external[k].address
      self_link   = v.self_link
    }
  }
}

output "internal_addresses" {
  description = "Internal IP addresses created"
  value = {
    for k, v in google_compute_address.internal : k => v.address
  }
}

output "external_addresses" {
  description = "External IP addresses created"
  value = {
    for k, v in google_compute_address.external : k => v.address
  }
}

output "taint_example" {
  description = "Example of how to taint a specific instance by name"
  value       = "terraform taint 'google_compute_instance.default[\"gcp-ns-lv01\"]'"
}
