output "ipv4_address_public" {
  value = try(resource.digitalocean_droplet.default[0].ipv4_address, "")
}
