output "cloudflare_tunnel_id" {
  value = try(cloudflare_tunnel.tunnel[0].id, "")
}

output "cloudflare_tunnel_cname" {
  value = try(cloudflare_tunnel.tunnel[0].cname, "")
}
