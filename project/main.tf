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

# random secret for gatekeeper-policy-manager
resource "random_password" "gpm" {
  length  = 16
  special = true
}

module "secret_generated" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  for_each = {
    "gpm" = random_password.gpm.result
  }

  name                 = "/${var.project}/${var.environment}/cluster-secret/${each.key}"
  value                = each.value
  type                 = "SecureString"
  secure_type          = true
  description          = "Secret stored in AWS Parameter Store"
  ignore_value_changes = true
}

locals {
  # Specifying here to allow re-use in policy. 
  # Name used there needs to match actual name of the idp_id.
  # See: https://github.com/cloudflare/terraform-provider-cloudflare/issues/2328#issuecomment-1492031130
  github_idp_name = "GitHub"

  # Subdomains (of var.extenal_domain) to set up DNS and Access for
  subdomains = [
    {
      name       = "www2",
      restricted = var.environment == "prod" ? false : true
    },
    {
      name        = "www-test",
      restricted  = true
      monitor     = true
      monitor_uri = "/robots.txt?nr-health-check"
    },
    {
      name       = "podinfo",
      restricted = true
    },
  ]

  servers_enabled_keys = [for key, s in var.cloud_servers : key if s.enabled == true]
  setup_dns_apps       = (length(local.servers_enabled_keys) > 0)
  monitors_enabled     = (length(local.servers_enabled_keys) > 0)
  target_tunnel_cname  = module.server[var.active_server].cloudflare_tunnel_cname

  slack_alerts_channel = {
    name = "alerts"
    id   = "C07GCL5N4F5"
  }
  slack_notifications_channel = {
    name = "notifications"
    id   = "C05UMQRQZ52"
  }
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
module "server" {
  for_each = var.cloud_servers

  source = "../modules/generic_cloud_server"

  enabled = each.value.enabled

  name                    = each.key
  environment             = var.environment
  cloud                   = each.value.cloud
  cloud_settings          = try(each.value.cloud_settings[each.value.cloud], {})
  target_revision         = try(each.value.target_revision, "main")
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

data "cloudflare_access_identity_provider" "github" {
  name       = local.github_idp_name
  account_id = data.cloudflare_accounts.main.accounts[0].id
}

resource "cloudflare_access_group" "tbnl_admin" {
  account_id = data.cloudflare_accounts.main.accounts[0].id
  name       = "TBNL ${var.environment} admins"

  include {
    email = split(",", data.aws_ssm_parameter.secret["cloudflare_access_email_adresses"].value)
    github {
      name                 = local.github_idp_name
      identity_provider_id = data.cloudflare_access_identity_provider.github.id
    }
  }
}

resource "cloudflare_access_service_token" "tbnl_health_checks" {
  account_id           = data.cloudflare_accounts.main.accounts[0].id
  name                 = "TBNL ${var.environment} health checks"
  duration             = "8760h"
  min_days_for_renewal = 60
  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_access_group" "tbnl_health_checks" {
  account_id = data.cloudflare_accounts.main.accounts[0].id
  name       = "TBNL ${var.environment} health checks"

  include {
    service_token = [cloudflare_access_service_token.tbnl_health_checks.id]
  }
}

module "cloudflare_app" {
  for_each = {
    for subdomain in local.subdomains : "${subdomain.name}-${var.environment}" => subdomain
  }

  source = "../modules/cf_tunneled_app"

  cf_zone_name = var.external_domain
  tunnel_cname = coalesce(local.target_tunnel_cname, "placeholder-no-tunnel-active")
  subdomain    = each.value.name
  restricted   = try(each.value.restricted, false)

  cf_access_groups        = [cloudflare_access_group.tbnl_admin.id]
  cf_access_groups_health = [cloudflare_access_group.tbnl_health_checks.id]
}

# Cloudflare rules
# ================
#
module "cloudflare_zone_config" {
  source = "../modules/cf_zone_config"

  cf_zone_name = var.external_domain
}

# New Relic cluster observability
# ===============================
#
# Alert rules, policies, workflows, etc.
#
module "nr_cluster_observability" {
  source = "../modules/nr_cluster_observability"

  environment = var.environment

  slack_notification_destination_name = "TBNL"
  slack_prio_channel                  = var.environment == "prod" ? local.slack_alerts_channel : local.slack_notifications_channel
  slack_noise_channel                 = local.slack_notifications_channel
}

# New Relic synthetics monitors
# =============================
#
module "monitor" {
  for_each = {
    for subdomain in local.subdomains : "${subdomain.name}-${var.environment}" => subdomain if try(subdomain.monitor, false) == true
  }

  source = "../modules/nr_monitor"

  zone_name   = var.external_domain
  subdomain   = each.value.name
  uri         = each.value.monitor_uri
  status      = local.monitors_enabled ? "ENABLED" : "DISABLED"
  environment = var.environment

  headers = [
    {
      key   = "CF-Access-Client-Id"
      value = cloudflare_access_service_token.tbnl_health_checks.client_id
    },
    {
      key   = "CF-Access-Client-Secret"
      value = cloudflare_access_service_token.tbnl_health_checks.client_secret
    }
  ]
}
