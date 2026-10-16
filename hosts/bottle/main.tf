# Provisions bottle and installs NixOS on it. Run from this directory with
# TF_VAR_state_passphrase set, e.g. from ~/secret/bottle-state-passphrase.
# Prefer an aarch64-linux host such as dragnipur, so nixos-anywhere can build
# bottle's system locally.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.7"
    }
  }

  # The state is committed to a public repo, so it's encrypted at rest.
  encryption {
    key_provider "pbkdf2" "main" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }
    state {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}

# Ephemeral rather than sensitive, which would write it to saved plan files.
variable "state_passphrase" {
  type      = string
  ephemeral = true
}

provider "google" {
  project = "negz-ai"
  region  = "us-west1"
  zone    = "us-west1-c"
}

resource "google_compute_address" "bottle" {
  name = "bottle"
}

resource "google_compute_instance" "bottle" {
  name                      = "bottle"
  machine_type              = "c4a-standard-8"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      # Only needs to boot far enough for nixos-anywhere to replace it.
      image = "debian-cloud/debian-13-arm64"
      type  = "hyperdisk-balanced"
      size  = 250

      # Hyperdisk Balanced includes 3,000 IOPS and 140 MiB/s. Its defaults for
      # a 250 GiB volume provision and bill for more. Changing these here
      # replaces the VM and its disk.
      provisioned_iops       = 3000
      provisioned_throughput = 140
    }
  }

  network_interface {
    network  = "default"
    nic_type = "GVNIC" # Required by C4A.
    access_config {
      nat_ip = google_compute_address.bottle.address
    }
  }

  metadata = {
    ssh-keys = "negz:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
  }
}

# Installs once per instance, so replacing the VM reinstalls on the next apply.
# Later changes to bottle's NixOS config are deployed with nixos-rebuild.
#
# If the install fails after nixos-anywhere has kexec'd into its installer, a
# plain retry hangs because the installer has no negz user to SSH in as.
# Recover with tofu apply -replace=google_compute_instance.bottle.
module "install" {
  source = "github.com/nix-community/nixos-anywhere//terraform/install?ref=1.13.0"

  flake       = "${abspath("${path.module}/../..")}#bottle"
  target_host = google_compute_address.bottle.address
  instance_id = google_compute_instance.bottle.instance_id

  # Debian's GCE image disables root login. It creates this user from the
  # ssh-keys metadata, with passwordless sudo.
  target_user = "negz"
}

output "ip" {
  value = google_compute_address.bottle.address
}
