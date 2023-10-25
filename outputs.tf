output "state_bucket_name" {
  value = local.state_bucket
}

output "state_dynamodb_table_name" {
  value = local.state_dynamodb_table
}

output "temp_cloudflare_tunnel_cname" {
  value = module.server_poc_1.cloudflare_tunnel_cname
}
