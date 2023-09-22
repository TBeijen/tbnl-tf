data "digitalocean_image" "ubuntu_22_04" {
  count = var.enabled ? 1 : 0

  slug = "ubuntu-22-04-x64"
}

resource "digitalocean_ssh_key" "ssh2022" {
  count = local.count && var.ssh_public_key != ""

  name       = "tibobeijen+ssh2022_ed25519"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "digitalocean_droplet" "poc_1" {
  count = var.enabled ? 1 : 0

  image     = data.digitalocean_image.ubuntu_22_04.id
  name      = var.name
  region    = "ams2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = var.ssh_public_key != "" ? [digitalocean_ssh_key.ssh2022[0].fingerprint] : []
#   user_data = templatefile("${path.root}/templates/cloud-config.yaml.tpl", {
#     auth_key = tailscale_tailnet_key.cloud_server.key
#   })
}

# Egress only firewall, dedicated to single host
resource "digitalocean_firewall" "poc" {
  count = var.enabled ? 1 : 0

  name = var.name

  droplet_ids = [digitalocean_droplet.poc_1[0].id]

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
