terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45.0"
    }
  }
}

data "hcloud_image" "default" {
  count = var.enabled ? 1 : 0

  name              = var.image_name
  with_architecture = "x86"
}

data "hcloud_ssh_key" "default" {
  count = (var.enabled && var.ssh_key_name != "") ? 1 : 0

  name = var.ssh_key_name
}

resource "hcloud_server" "default" {
  count = var.enabled ? 1 : 0

  image       = data.hcloud_image.default[0].id
  name        = var.name
  location    = "nbg1"
  server_type = var.instance_type
  ssh_keys    = var.ssh_key_name != "" ? [data.hcloud_ssh_key.default[0].id] : []
  user_data   = var.user_data

  firewall_ids = [hcloud_firewall.default[0].id]

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Egress only firewall, dedicated to single host
resource "hcloud_firewall" "default" {
  count = var.enabled ? 1 : 0

  name = var.name

  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}
