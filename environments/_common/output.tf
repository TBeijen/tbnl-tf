output "cloud_servers" {
  value = module.tbnl.cloud_servers
}

output "quick_start" {
  value = { for color, server in module.tbnl.cloud_servers : color => [
    "ssh root@${server.instance_name}",
    "http://argocd.${server.cluster_name}.internal.tbnl.nl/",
    "http://podinfo.${server.cluster_name}.internal.tbnl.nl/",
    "http://traefik.${server.cluster_name}.internal.tbnl.nl/dashboard/",
  ] if server.enabled == true }
}
