terraform {
  required_version = "~> 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.30.0"
    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "~> 0.13.10"
    }    
  }
  # Need to come up with hack to configure remote state based on vars or workspace
  backend "s3" {
    bucket         = "tfstate-tbnl-tf-test"
    key            = "test/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tfstate-tbnl-tf-test"
    encrypt        = true
  }
}

locals {
  state_bucket            = "tfstate-${var.project}-${var.environment}"
  state_dynamodb_table    = "tfstate-${var.project}-${var.environment}"
  tailscale_tags          = ["tag:cloud-server"]
  provider_secrets = {for name in [
    "digital_ocean",
    "tailscale_client_id",
    "tailscale_client_secret",
  ]: name => "/${var.project}/${var.environment}/${name}"}
}

provider "aws" {
  region = "eu-west-1"
}

module "remote_state" {
  source = "./modules/aws_s3_remote_state"

  bucket_name    = local.state_bucket
  dynamodb_table = local.state_dynamodb_table
}

# When adding a new secret: Run once with --target=module.provider_secret
module "provider_secret" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  for_each = local.provider_secrets

  name                 = each.value
  value                = "api-token-value"
  type                 = "SecureString"
  secure_type          = true
  description          = "Digital Ocean API token"
  ignore_value_changes = true
}

data "aws_ssm_parameter" "provider_secret" {
  for_each = local.provider_secrets

  name = each.value
}

# Configure providers
provider "digitalocean" {
  token = data.aws_ssm_parameter.provider_secret["digital_ocean"].value
}

provider "tailscale" {
  oauth_client_id     = data.aws_ssm_parameter.provider_secret["tailscale_client_id"].value
  oauth_client_secret = data.aws_ssm_parameter.provider_secret["tailscale_client_secret"].value
  scopes              = ["devices"]
}


resource "tailscale_tailnet_key" "cloud_server" {
  reusable      = true
  preauthorized = true
  # Using ephemeral to have servers automatically de-register from tailscale when removed
  ephemeral     = true
  tags          = local.tailscale_tags
}