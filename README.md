# Terraform for_each with google_compute_address - Working Solution

## The Problem

You have VMs that need static IP addresses (both internal and external) that were created years ago as ephemeral IPs and had to be imported. You need to:

1. Define explicit `google_compute_address` resources to preserve these IPs
2. Reference those address resources in your `google_compute_instance` for_each loop
3. Avoid hardcoding IP addresses as strings in your locals
4. Maintain the ability to use `terraform taint 'google_compute_instance.default["gcp-ns-lv01"]'`
5. Keep the `null` coalescing pattern for optional fields

## The Solution

**Key Insight:** Don't put IP addresses in your VM data structure. Instead:

1. Create addresses with `for_each` using instance names as keys
2. Reference those addresses in instances using `google_compute_address.internal[each.key].address`

## How It Works

### 1. Separate Data Structures

```hcl
locals {
  # VM configs WITHOUT IPs
  vms = {
    "gcp-ns-lv01" = {
      zone           = "us-west1-c"
      private_subnet = "shared-private-west"
      machine_type   = null  # Uses default
      # ... other config
    }
  }

  # Address configs separately with the actual IPs
  addresses = {
    "gcp-ns-lv01" = {
      region = "us-west1"
      subnet = "shared-private-west"
      int_ip = "10.20.40.18"
      ext_ip = "35.230.55.88"
    }
  }
}
```

### 2. Create Addresses with for_each

```hcl
resource "google_compute_address" "internal" {
  for_each     = local.addresses
  name         = "${each.key}-internal"
  address_type = "INTERNAL"
  address      = each.value.int_ip
  # ... rest of config
}

resource "google_compute_address" "external" {
  for_each     = local.addresses
  name         = "${each.key}-external"
  address_type = "EXTERNAL"
  address      = each.value.ext_ip
}
```

### 3. Reference Addresses in Instances

```hcl
resource "google_compute_instance" "default" {
  for_each = local.vms
  name     = each.key

  network_interface {
    # THE KEY: Reference using [each.key]
    network_ip = google_compute_address.internal[each.key].address

    access_config {
      nat_ip = google_compute_address.external[each.key].address
    }
  }
}
```

## Why This Works

1. **Terraform knows all keys upfront** - Both `local.vms` and `local.addresses` are static maps
2. **Automatic dependencies** - Terraform sees the references and creates addresses before instances
3. **Same keys in both maps** - `[each.key]` works because keys match across maps
4. **No hardcoded values** - IPs are resource attributes, not strings
5. **Named key targeting** - `terraform taint 'google_compute_instance.default["gcp-ns-lv01"]'` works perfectly

## Usage

### 1. Set Variables

Create `terraform.tfvars`:

```hcl
project      = "your-gcp-project-id"
host_project = "your-shared-vpc-host-project"
```

### 2. Initialize and Plan

```bash
terraform init
terraform plan
```

### 3. Apply

```bash
terraform apply
```

## Adding More VMs

Just add to both maps with matching keys:

```hcl
locals {
  vms = {
    "gcp-ns-lv01" = { ... }
    "gcp-ns-lv02" = { ... }
    "gcp-ns-lv03" = { ... }
    "gcp-ns-lv04" = { ... }  # New VM
  }

  addresses = {
    "gcp-ns-lv01" = { ... }
    "gcp-ns-lv02" = { ... }
    "gcp-ns-lv03" = { ... }
    "gcp-ns-lv04" = { int_ip = "...", ext_ip = "..." }  # Matching key
  }
}
```

## Benefits

✅ **No hardcoded IP strings** in your VM configs
✅ **Resource attributes** are properly referenced
✅ **Named key targeting** works (`terraform taint`)
✅ **No count() index shifting** issues
✅ **Null coalescing pattern** preserved for optional fields
✅ **Clean separation** between VM config and IP allocation

## Example Commands

```bash
# Target a specific instance
terraform taint 'google_compute_instance.default["gcp-ns-lv01"]'

# Plan for a specific instance
terraform plan -target='google_compute_instance.default["gcp-ns-lv01"]'

# Show outputs
terraform output instances
terraform output external_addresses
```

## Files in This Example

- **`main.tf`** - Core resources demonstrating the pattern
- **`data.tf`** - Subnet data sources for your shared VPC
- **`providers.tf`** - GCP provider configuration
- **`variables.tf`** - Required variables (project, host_project, etc.)
- **`outputs.tf`** - Instance details and IP mappings
- **`.gitignore`** - Excludes credentials and state files

## Notes

- This example uses 3 VMs to demonstrate the pattern
- Expand the maps to include all 6 of your VMs
- Update `data.tf` with your actual subnet references
- The pattern scales to any number of VMs
