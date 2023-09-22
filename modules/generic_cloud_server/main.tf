terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "~> 0.13.10"
    }    
  }
}

resource "random_pet" "cloud_server" {
  count = var.enabled ? 1 : 0

  length  = 1
  keepers = {}
}

locals {
  name = format("%s%s", 
    var.name,
    (var.enabled && var.add_random_pet_suffix) ? "-${random_pet.cloud_server[0].id}" : ""
  )

  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tpl", {
    auth_key = try(tailscale_tailnet_key.cloud_server[0].key, "")
  })

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

