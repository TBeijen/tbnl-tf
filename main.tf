terraform {
  required_version = "~> 1.5.7"
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
  # Need to come up with hack to configure remote state based on vars or workspace
  backend "s3" {
    bucket         = "tfstate-tbnl-tf-prod"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tfstate-tbnl-tf-prod"
    encrypt        = true
  }
}

locals {
  state_bucket         = "tfstate-${var.project}-${var.environment}"
  state_dynamodb_table = "tfstate-${var.project}-${var.environment}"
  project_secrets = { for name in [
    "cloudflare",
    "digital_ocean",
    "tailscale_client_id",
    "tailscale_client_secret",
    "pushover_user_key",
    "pushover_api_key_tbnl_infra",
  ] : name => "/${var.project}/${var.environment}/secret/${name}" }
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

module "terraform_state" {
  source = "./modules/aws_s3_remote_state"

  bucket_name    = local.state_bucket
  dynamodb_table = local.state_dynamodb_table
}

# When adding a new secret: Run once with --target=module.secret
module "secret" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  for_each = local.project_secrets

  name                 = each.value
  value                = "api-token-value"
  type                 = "SecureString"
  secure_type          = true
  description          = "Digital Ocean API token"
  ignore_value_changes = true
}

data "aws_ssm_parameter" "secret" {
  for_each = local.project_secrets

  name = each.value
}

# Set digital ocean key
resource "digitalocean_ssh_key" "default" {
  name       = "${var.environment}-tbnl_ed25519"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

module "server_poc_1" {
  source = "./modules/generic_cloud_server"

  enabled = true

  name               = "poc-1"
  environment        = var.environment
  cloud              = "digital_ocean"
  ssh_key_name       = digitalocean_ssh_key.default.name
  pushover_user_key  = data.aws_ssm_parameter.secret["pushover_user_key"].value
  pushover_api_token = data.aws_ssm_parameter.secret["pushover_api_key_tbnl_infra"].value
}

module "server_poc_2" {
  source = "./modules/generic_cloud_server"

  enabled = false

  name               = "poc-2"
  environment        = var.environment
  cloud              = "digital_ocean"
  ssh_key_name       = digitalocean_ssh_key.default.name
  pushover_user_key  = data.aws_ssm_parameter.secret["pushover_user_key"].value
  pushover_api_token = data.aws_ssm_parameter.secret["pushover_api_key_tbnl_infra"].value
}
