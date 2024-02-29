output "ipv4_address_public" {
  value = try(resource.hcloud_server.default[0].ipv4_address, "")
}
