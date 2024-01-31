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
      enabled = true
      cloud   = "digital_ocean"
    }
    green = {
      enabled = false
      cloud   = "digital_ocean"
    }
  }
}



# module "server_poc_1" {
#   source = "../modules/generic_cloud_server"

#   enabled = false

#   name               = "poc-1"
#   environment        = var.environment
#   cloud              = "digital_ocean"
#   ssh_key_name       = var.do_provision_ssh_key == true ? digitalocean_ssh_key.default[0].name : local.do_ssh_key_name
#   pushover_user_key  = data.aws_ssm_parameter.secret["pushover_user_key"].value
#   pushover_api_token = data.aws_ssm_parameter.secret["pushover_api_key_tbnl_infra"].value
# }

# module "server_poc_2" {
#   source = "../modules/generic_cloud_server"

#   enabled = false

#   name               = "poc-2"
#   environment        = var.environment
#   cloud              = "digital_ocean"
#   ssh_key_name       = var.do_provision_ssh_key == true ? digitalocean_ssh_key.default[0].name : local.do_ssh_key_name
#   pushover_user_key  = data.aws_ssm_parameter.secret["pushover_user_key"].value
#   pushover_api_token = data.aws_ssm_parameter.secret["pushover_api_key_tbnl_infra"].value
# }
