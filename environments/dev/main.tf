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

  backend "s3" {
    bucket         = "296093601437-tfstate"
    key            = "tbnl-tf/dev/terraform.tfstate" # <project-name>/<env>/terraform.tfstate
    region         = "eu-west-1"
    dynamodb_table = "tfstate-tbnl-tf-dev" # tfstate-<project-name>-<env>
    encrypt        = true
  }
}

locals {
  project     = "tbnl-tf"
  environment = "dev"
}

module "tbnl" {
  source = "../../project"

  project              = local.project
  environment          = local.environment
  state_bucket         = "296093601437-tfstate"
  state_dynamodb_table = "tfstate-tbnl-tf-dev"
  project_secrets      = local.project_secrets

  cloud_servers = {
    blue = {
      enabled = false
      cloud   = "digital_ocean"
    }
    green = {
      enabled = true
      cloud   = "digital_ocean"
    }
  }
  active_server = "green"
}
