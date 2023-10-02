terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "~> 0.13.10"
    }    
  }
}

resource "random_pet" "cloud_server" {
  count = var.enabled ? 1 : 0

  length  = 1
  keepers = {}
}

locals {
  name = "${var.environment}-${var.name}"
  # Instance name is used to help identify generations of instances, 
  # e.g. in Tailscale where previous identical machine remains in overview for a period
  instance_name = format("%s%s", 
    local.name,
    (var.enabled && var.add_random_pet_suffix) ? "-${random_pet.cloud_server[0].id}" : ""
  )

  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tpl", {
    argocd_install_source = "https://raw.githubusercontent.com/TBeijen/tbnl-gitops/main/argocd/install.yaml"
    argocd_app_of_apps_source = "https://raw.githubusercontent.com/TBeijen/tbnl-gitops/main/argocd/app-of-apps.yaml"
    aws_access_key_id = try(aws_iam_access_key.cloud_server_access_key[0].id, "")
    aws_secret_access_key = try(aws_iam_access_key.cloud_server_access_key[0].secret, "")
    aws_ssm_target_kubeconfig = "arn:aws:ssm:eu-west-1:127613428667:parameter/tbnl-tf/${var.environment}/kubeconfig/${var.name}"
    name = local.instance_name
    pushover_user_key = var.pushover_user_key
    pushover_api_token = var.pushover_api_token
    tailscale_auth_key = try(tailscale_tailnet_key.cloud_server[0].key, "")
  })

  tailscale_tags = ["tag:cloud-server"]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_user" "cloud_server_identity" {
  count = var.enabled ? 1 : 0

  name  = format("server-identity-%s", local.instance_name)
  path  = "/system/"
}

resource "aws_iam_access_key" "cloud_server_access_key" {
  count = var.enabled ? 1 : 0

  user   = aws_iam_user.cloud_server_identity[0].name
  status = "Active"
}

resource "tailscale_tailnet_key" "cloud_server" {
  count = var.enabled ? 1 : 0

  description   = local.instance_name
  reusable      = true
  preauthorized = true
  # Using ephemeral to have servers automatically de-register from tailscale when removed
  ephemeral     = true
  tags          = local.tailscale_tags
}

module "digital_ocean_server" {
  source = "../server_digital_ocean"
  
  enabled = (var.enabled && var.cloud == "digital_ocean")

  name           = local.instance_name
  ssh_key_name   = var.ssh_key_name
  user_data      = local.user_data
}