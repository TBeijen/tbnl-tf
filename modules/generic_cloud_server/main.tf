terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "~> 0.13.10"
    }    
  }
}

resource "random_pet" "server" {
  count = local.count

  length  = 1
  keepers = {}
}

locals {
  count = var.enabled ? 1 : 0

  name = format("%s%s", 
    var.name,
    (var.add_random_pet_suffix ? "-${random_pet.server[0].id}" : "")
  )

  tailscale_tags = ["tag:cloud-server"]
}

resource "tailscale_tailnet_key" "cloud_server" {
  count = var.enabled ? 1 : 0

  description   = var.name
  reusable      = true
  preauthorized = true
  # Using ephemeral to have servers automatically de-register from tailscale when removed
  ephemeral     = true
  tags          = local.tailscale_tags
}