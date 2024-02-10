terraform {
  required_version = "~> 1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.16.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.30.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.10"
    }
  }
}

module "terraform_state" {
  source = "../modules/aws_s3_remote_state"

  bucket_name    = var.state_bucket
  dynamodb_table = var.state_dynamodb_table
}

# When adding a new secret: Run once with --target=module.secret
module "secret" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  for_each = var.project_secrets

  name                 = each.value
  value                = "api-token-value"
  type                 = "SecureString"
  secure_type          = true
  description          = "Secret stored in AWS Parameter Store"
  ignore_value_changes = true
}

data "aws_ssm_parameter" "secret" {
  for_each = var.project_secrets

  name = each.value
}

locals {
  do_ssh_key_name = "tbnl_ed25519"

  # Subdomains (of var.extenal_domain) to set up DNS and Access for
  subdomains = [
    {
      name       = "www2",
      restricted = var.environment == "prod" ? false : true
    },
    {
      name       = "www-test",
      restricted = true
    },
    {
      name       = "podinfo",
      restricted = true
    },
  ]

  servers_enabled_keys = [for key, s in var.cloud_servers : key if s.enabled == true]
  setup_dns_apps       = (length(local.servers_enabled_keys) > 0)
  target_tunnel_cname  = module.server[var.active_server].cloudflare_tunnel_cname
}

# Validate enabled/active flags.
resource "terraform_data" "validate_servers" {
  lifecycle {
    precondition {
      condition = !(
        length(local.servers_enabled_keys) < 1 &&
        var.environment == "prod"
      )
      error_message = "On environment=prod, at least one server should be enabled"
    }
    precondition {
      condition = (
        length(local.servers_enabled_keys) == 0 ||
        contains(local.servers_enabled_keys, var.active_server)
      )
      error_message = "Only a server that is enabled can be active"
    }
  }
}

# Cloud server(s)
# ===============
#

# Set digital ocean key
resource "digitalocean_ssh_key" "default" {
  count = var.do_provision_ssh_key == true ? 1 : 0

  name       = local.do_ssh_key_name
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

module "server" {
  for_each = var.cloud_servers

  source = "../modules/generic_cloud_server"

  enabled = each.value.enabled

  name                    = each.key
  environment             = var.environment
  cloud                   = each.value.cloud
  ssh_key_name            = var.do_provision_ssh_key == true ? digitalocean_ssh_key.default[0].name : local.do_ssh_key_name
  pushover_user_key       = data.aws_ssm_parameter.secret["pushover_user_key"].value
  pushover_api_token      = data.aws_ssm_parameter.secret["pushover_api_key_tbnl_infra"].value
  external_domain         = var.external_domain
  cloudflare_account_name = var.cloudflare_account_name
}

# Cloudflare DNS and Access
# =========================
#
data "cloudflare_accounts" "main" {
  name = var.cloudflare_account_name
}

module "cloudflare_app" {
  for_each = {
    for subdomain in local.subdomains : "${subdomain.name}-${var.environment}" => subdomain
  }

  source = "../modules/cf_tunneled_app"

  cf_account_id = data.cloudflare_accounts.main.accounts[0].id
  cf_zone_name  = var.external_domain
  tunnel_cname  = coalesce(local.target_tunnel_cname, "placeholder-no-tunnel-active")
  subdomain     = each.value.name
  restricted    = try(each.value.restricted, false)
}
