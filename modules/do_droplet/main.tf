data "digitalocean_image" "ubuntu_22_04" {
  count = var.enabled ? 1 : 0

  slug = "ubuntu-22-04-x64"
}

resource "digitalocean_ssh_key" "default" {
  count = local.count && var.ssh_public_key != ""

  name       = var.name
  public_key = var.ssh_public_key
}

resource "digitalocean_droplet" "default" {
  count = var.enabled ? 1 : 0

  image     = data.digitalocean_image.ubuntu_22_04.id
  name      = var.name
  region    = "ams2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = var.ssh_public_key != "" ? [digitalocean_ssh_key.default[0].fingerprint] : []
#   user_data = templatefile("${path.root}/templates/cloud-config.yaml.tpl", {
#     auth_key = tailscale_tailnet_key.cloud_server.key
#   })
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
