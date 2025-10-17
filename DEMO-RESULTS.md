# Solution Demonstration

## Your Question

> "I WANT to use `google_compute_address.foo.address` in the instance block, but I've found I have to manually put the actual IP address into the list - I can't figure out a way to de-reference to the resource itself."

## The Answer

**You CAN use `google_compute_address.foo.address`!** You just need to use `for_each` on the address resources too, then reference them with bracket notation.

## The Pattern

Instead of this (what you were trying):

```hcl
# ❌ This doesn't work - can't put resource refs in the source data
locals {
  vms = [{
    instance_name = "gcp-ns-lv01"
    int_ip        = google_compute_address.lv01-int.address  # ❌ Can't do this
    ext_ip        = google_compute_address.lv01-ext.address  # ❌ Can't do this
  }]
}
```

Do this:

```hcl
# ✅ This works!
locals {
  # VM configs WITHOUT IPs
  vms = {
    "gcp-ns-lv01" = { zone = "us-west1-c", ... }
  }

  # Address configs WITH IPs
  addresses = {
    "gcp-ns-lv01" = { int_ip = "10.20.40.18", ext_ip = "35.230.55.88" }
  }
}

# Addresses use for_each
resource "google_compute_address" "internal" {
  for_each = local.addresses
  name     = "${each.key}-internal"
  address  = each.value.int_ip
}

resource "google_compute_address" "external" {
  for_each = local.addresses
  name     = "${each.key}-external"
  address  = each.value.ext_ip
}

# Instances reference addresses using [each.key]
resource "google_compute_instance" "default" {
  for_each = local.vms

  network_interface {
    network_ip = google_compute_address.internal[each.key].address  # ✅ Works!
    access_config {
      nat_ip = google_compute_address.external[each.key].address   # ✅ Works!
    }
  }
}
```

## What Changes From Your Current Code

### Before (Individual Address Resources)

```hcl
resource "google_compute_address" "lv01-int" {
  name         = "gcp-ns-lv01-internal"
  address_type = "INTERNAL"
  region       = "us-west1"
  address      = "10.20.40.18"
  # ...
}

resource "google_compute_address" "lv01-ext" {
  name         = "gcp-ns-lv01-external"
  address_type = "EXTERNAL"
  region       = "us-west1"
  address      = "35.230.55.88"
}

# Repeat for lv02, lv03, lv04, lv05, lv06...
```

### After (for_each Address Resources)

```hcl
resource "google_compute_address" "internal" {
  for_each     = local.addresses
  name         = "${each.key}-internal"
  address_type = "INTERNAL"
  region       = each.value.region
  address      = each.value.int_ip
  # ...
}

resource "google_compute_address" "external" {
  for_each     = local.addresses
  name         = "${each.key}-external"
  address_type = "EXTERNAL"
  region       = each.value.region
  address      = each.value.ext_ip
}

# All 6 VMs created from one resource block!
```

## Your Concerns - All Addressed ✅

### 1. "I really quite like being able to terraform taint..."

**Still works!** Same syntax:

```bash
terraform taint 'google_compute_instance.default["gcp-ns-lv01"]'
```

### 2. "I'm scared of using count() and having instances changing indexes"

**No count() needed!** Using `for_each` with maps means named keys, not numeric indexes.

### 3. "The 'foo == null ? bar : foo' pattern has been great"

**Preserved!** All your optional fields still work:

```hcl
machine_type = each.value.machine_type == null ? var.ce_machine_type : each.value.machine_type
image        = each.value.image == null ? "debian-cloud/debian-11" : each.value.image
disk_size    = each.value.disk_size == null ? 10 : each.value.disk_size
```

### 4. "Long-term maint of these boxen requires changes one at a time"

**Even easier!** Change one VM's config in the map, only that instance gets updated.

## Resource Names in State

### Before
```
google_compute_address.lv01-int
google_compute_address.lv01-ext
google_compute_address.lv02-int
google_compute_address.lv02-ext
...
```

### After
```
google_compute_address.internal["gcp-ns-lv01"]
google_compute_address.external["gcp-ns-lv01"]
google_compute_address.internal["gcp-ns-lv02"]
google_compute_address.external["gcp-ns-lv02"]
...
```

## Migration Path

If you already have the individual resources in state:

```bash
# Move each address to the new for_each structure
terraform state mv \
  'google_compute_address.lv01-int' \
  'google_compute_address.internal["gcp-ns-lv01"]'

terraform state mv \
  'google_compute_address.lv01-ext' \
  'google_compute_address.external["gcp-ns-lv01"]'

# Repeat for all VMs
```

Or use `terraform import` with the new structure on a fresh state.

## Bottom Line

You were right that you can't put resource references in the source data for `for_each`.

But you CAN:
- Create addresses with `for_each`
- Reference them in instances with `[each.key]`
- Get all the benefits you want

The code in this directory is a working example using your actual VM names, zones, subnets, and the roadkill.org domain. Just add your project IDs and you're ready to go!
