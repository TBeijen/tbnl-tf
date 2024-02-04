output "enabled" {
  value = var.enabled
}

output "cluster_name" {
  value = local.cluster_name
}

output "instance_name" {
  value = local.instance_name
}

output "cloudflare_tunnel_id" {
  value = try(cloudflare_tunnel.tunnel[0].id, "")
}

output "cloudflare_tunnel_cname" {
  value = try(cloudflare_tunnel.tunnel[0].cname, "")
}
