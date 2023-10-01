terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.30.0"
    }
  }
}

data "digitalocean_image" "ubuntu_22_04" {
  count = var.enabled ? 1 : 0

  slug = "ubuntu-22-04-x64"
}

data "digitalocean_ssh_key" "default" {
  count = (var.enabled && var.ssh_key_name != "") ? 1 : 0

  name = var.ssh_key_name
}

resource "digitalocean_droplet" "default" {
  count = var.enabled ? 1 : 0

  image     = data.digitalocean_image.ubuntu_22_04[0].id
  name      = var.name
  region    = "ams2"
  size      = "s-1vcpu-2gb"
  ssh_keys  = var.ssh_key_name != "" ? [data.digitalocean_ssh_key.default[0].fingerprint] : []
  user_data = var.user_data

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Egress only firewall, dedicated to single host
resource "digitalocean_firewall" "default" {
  count = var.enabled ? 1 : 0

  name = var.name

  droplet_ids = [digitalocean_droplet.default[0].id]

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
