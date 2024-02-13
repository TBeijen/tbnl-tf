
# IMPORTANT!
#
# This file is environment-agnostic and will be symlinked to any environment
#
# Goal is to:
# - point to directory and run (short) terraform plan/apply commands
# - Avoid any error or env/vars mixup
# - Not in correct SSO profile? Immediate fail on lack of state access
#
locals {
  project_secrets = merge(
    { for name in [
      "cloudflare",
      "cloudflare_access_email_adresses",
      "digital_ocean",
      "tailscale_client_id",
      "tailscale_client_secret",
      "pushover_user_key",
      "pushover_api_key_tbnl_infra",
      ] : name => "/${local.project}/${local.environment}/secret/${name}"
    },

    { for name in [
      "grafana-cloud"
      ] : name => "/${local.project}/${local.environment}/cluster-secret/${name}"
    }
  )
}

# Load secrets
data "aws_ssm_parameter" "secret" {
  for_each = local.project_secrets

  name = each.value
}

# Configure providers
provider "aws" {
  region = "eu-west-1"
}

provider "cloudflare" {
  api_token = data.aws_ssm_parameter.secret["cloudflare"].value
}

provider "digitalocean" {
  token = data.aws_ssm_parameter.secret["digital_ocean"].value
}

provider "tailscale" {
  oauth_client_id     = data.aws_ssm_parameter.secret["tailscale_client_id"].value
  oauth_client_secret = data.aws_ssm_parameter.secret["tailscale_client_secret"].value
  scopes              = ["devices"]
}

