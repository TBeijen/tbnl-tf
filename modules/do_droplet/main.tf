# Create a new Droplet using the SSH key
resource "random_pet" "server" {
  count = local.count

  length  = 1
  keepers = {}
}

locals {
  count = var.enabled ? 1 : 0

  name = format("%s%s", 
    var.name,
    (var.add_random_pet_suffix ? "-${random_pet.server.id}" : "")
  )
}

data "digitalocean_image" "ubuntu_22_04" {
  count = local.count

  slug = "ubuntu-22-04-x64"
}

resource "digitalocean_ssh_key" "ssh2022" {
  count = local.count

  name       = "tibobeijen+ssh2022_ed25519"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "digitalocean_droplet" "poc_1" {
  count = local.count

  image     = data.digitalocean_image.ubuntu_22_04.id
  name      = local.name
  region    = "ams2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [digitalocean_ssh_key.ssh2022[0].fingerprint]
#   user_data = templatefile("${path.root}/templates/cloud-config.yaml.tpl", {
#     auth_key = tailscale_tailnet_key.cloud_server.key
#   })
}

# Egress only firewall, dedicated to single host
resource "digitalocean_firewall" "poc" {
  count = var.enabled ? 1 : 0

  name = local.name

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
