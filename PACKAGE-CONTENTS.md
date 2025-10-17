# Package Contents

This working Terraform example demonstrates the solution to your for_each + google_compute_address question.

## What's Included

### Core Configuration Files
- **`main.tf`** - The working solution using your actual VM names (gcp-ns-lv01, etc.), zones, and roadkill.org domain
- **`providers.tf`** - GCP provider configuration (uses gcloud auth)
- **`variables.tf`** - Variables for your project and host_project
- **`data.tf`** - Subnet data sources for your shared VPC
- **`outputs.tf`** - Shows instance details and IP mappings

### Documentation
- **`README.md`** - Complete usage guide and explanation
- **`DEMO-RESULTS.md`** - Direct answer to your question with before/after comparisons
- **`terraform.tfvars.example`** - Template for your project IDs

### Supporting Files
- **`.gitignore`** - Excludes credentials, state files, etc.

## The Key Pattern Demonstrated

```hcl
# Addresses use for_each
resource "google_compute_address" "internal" {
  for_each = local.addresses
  name     = "${each.key}-internal"
  address  = each.value.int_ip
}

# Instances reference addresses
resource "google_compute_instance" "default" {
  for_each = local.vms

  network_interface {
    network_ip = google_compute_address.internal[each.key].address  # ← The solution!
  }
}
```

## Quick Start

1. Extract this archive
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Fill in your GCP project IDs
4. Run `terraform init && terraform plan`

## What Changed From Your Code

✅ **Removed:** Hardcoded IP addresses in VM configs
✅ **Added:** `for_each` on address resources
✅ **Solution:** Reference addresses using `[each.key]` notation
✅ **Preserved:** All your optional field patterns and taint targeting

## Uses Your Actual Data

- Instance names: `gcp-ns-lv01`, `gcp-ns-lv02`, `gcp-ns-lv03`
- Zones: `us-west1-c`, `us-west1-b`, `us-east1-b`
- Subnets: `shared-private-west`, `shared-private-east`
- Domain: `roadkill.org`
- IP addresses: Your actual IPs (10.20.40.18, 35.230.55.88, etc.)

Just add your remaining 3 VMs to the maps and you're ready to go!

## No Credentials Included

This package contains NO credentials. Use `gcloud auth application-default login` or set the `GOOGLE_CREDENTIALS` environment variable.

## Questions?

Check `DEMO-RESULTS.md` first - it directly addresses your question about referencing `google_compute_address` resources.

---

Ready to use with your actual environment!
