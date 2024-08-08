
# IMPORTANT!
#
# This file is environment-agnostic and will be symlinked to any environment
#
# Goal is to:
# - point to directory and run (short) terraform plan/apply commands
# - Avoid any error or env/vars mixup
# - Not in correct SSO profile? Immediate fail on lack of state access
#

# Load secrets to configure providers
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

provider "hcloud" {
  token = data.aws_ssm_parameter.secret["hetzner"].value
}

provider "newrelic" {
  account_id = "4355133"
  api_key    = data.aws_ssm_parameter.secret["newrelic_api_key"].value
  region     = "EU"
}

provider "tailscale" {
  oauth_client_id     = data.aws_ssm_parameter.secret["tailscale_client_id"].value
  oauth_client_secret = data.aws_ssm_parameter.secret["tailscale_client_secret"].value
  scopes              = ["devices"]
}

