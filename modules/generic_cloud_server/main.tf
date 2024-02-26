terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
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
  # Cluster name combines environment and base name, but does not have random pet suffix
  # Used to identify K3S and ArgoCD clusters
  cluster_name = "${var.environment}-${var.name}"

  # Instance name is used to help identify generations of instances, 
  # e.g. in Tailscale where previous identical machine remains in overview for a period
  instance_name = format("%s%s",
    local.cluster_name,
    (var.enabled && var.add_random_pet_suffix) ? "-${random_pet.cloud_server[0].id}" : ""
  )

  aws_resources_common_name = "${var.project}-${var.environment}-${local.instance_name}"

  aws_ssm_target_kubeconfig_path   = "/${var.project}/${var.environment}/kubeconfig/${local.cluster_name}"
  aws_ssm_tunnel_secret_path       = "/${var.project}/${var.environment}/cluster-secret/cloudflare-tunnel/${local.cluster_name}"
  aws_ssm_example_secret_path      = "/${var.project}/${var.environment}/cluster-secret/example/${local.cluster_name}"
  aws_ssm_path_cluster_secrets_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/cluster-secret/*"

  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tpl", {
    argocd_install_source     = "https://raw.githubusercontent.com/TBeijen/tbnl-gitops/${var.target_revision}/applications/argocd/install.yaml"
    argocd_app_of_apps_source = "https://raw.githubusercontent.com/TBeijen/tbnl-gitops/${var.target_revision}/init/app-of-apps.application.yaml"
    aws_access_key_id         = try(aws_iam_access_key.cloud_server_access_key[0].id, "")
    aws_secret_access_key     = try(aws_iam_access_key.cloud_server_access_key[0].secret, "")
    aws_ssm_target_kubeconfig = local.aws_ssm_target_kubeconfig_path
    environment               = var.environment
    cluster_name              = local.cluster_name
    instance_name             = local.instance_name
    target_revision           = var.target_revision
    pushover_user_key         = var.pushover_user_key
    pushover_api_token        = var.pushover_api_token
    external_domain           = var.external_domain
    tailscale_auth_key        = try(tailscale_tailnet_key.cloud_server[0].key, "")
  })

  tailscale_tags = ["tag:cloud-server"]

  # Extract attributes of created server, depending on cloud type 
  cloud_server_attributes = {
    ipv4_address_public = element(concat(
      var.cloud == "digital_ocean" ? [module.digital_ocean_server.ipv4_address_public] : [],
    ), 0)
  }
}


# AWS
# ======================================
#
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Allow SSM
data "aws_iam_policy_document" "ssm" {
  count = var.enabled ? 1 : 0

  statement {
    sid = "AllowStoreKubeconfig"

    actions = [
      "ssm:PutParameter",
    ]

    resources = [
      "${module.ssm_kubeconfig.ssm_parameter_arn}",
    ]
  }

  statement {
    sid = "AllowReadClusterSecrets"

    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]

    resources = [
      "${local.aws_ssm_path_cluster_secrets_arn}",
    ]
  }
}

resource "aws_iam_policy" "ssm" {
  count = var.enabled ? 1 : 0

  name   = "ssm-${local.aws_resources_common_name}"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm[0].json
}

resource "aws_iam_user_policy_attachment" "ssm" {
  count = var.enabled ? 1 : 0

  user       = aws_iam_user.cloud_server_identity[0].name
  policy_arn = aws_iam_policy.ssm[0].arn
}

# Restrict to remote IP
# Note: 
#   Since it depends on the server ipv4, this policy is attached _after_ server is created.
#   This is the reason the policy is separate from the ssm policy which is needed _before_ the server is created.
data "aws_iam_policy_document" "ip_restrict" {
  count = var.enabled ? 1 : 0

  statement {
    sid       = "RestrictToServerIp"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = ["${local.cloud_server_attributes.ipv4_address_public}/32"]
    }

    condition {
      test     = "Bool"
      variable = "aws:ViaAWSService"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "ip_restrict" {
  count = var.enabled ? 1 : 0

  name   = "ip-restrict-${local.aws_resources_common_name}"
  path   = "/"
  policy = data.aws_iam_policy_document.ip_restrict[0].json
}

resource "aws_iam_user_policy_attachment" "ip_restrict" {
  count = var.enabled ? 1 : 0

  user       = aws_iam_user.cloud_server_identity[0].name
  policy_arn = aws_iam_policy.ip_restrict[0].arn
}

resource "aws_iam_user" "cloud_server_identity" {
  count = var.enabled ? 1 : 0

  name = local.aws_resources_common_name
  path = "/system/"
}

resource "aws_iam_access_key" "cloud_server_access_key" {
  count = var.enabled ? 1 : 0

  user   = aws_iam_user.cloud_server_identity[0].name
  status = "Active"

  depends_on = [
    # We need the policy to be present since server will upload kubeconfig during initialization
    aws_iam_user_policy_attachment.ssm,
  ]
}

# SSM parameter will be written by server during initialization.
# Nevertheless manage via Terraform to control lifecycle.
module "ssm_kubeconfig" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  create = var.enabled

  name                 = local.aws_ssm_target_kubeconfig_path
  value                = "placeholder"
  type                 = "SecureString"
  secure_type          = true
  description          = "Kubeconfig for k3s@${local.cluster_name}"
  ignore_value_changes = true
}


# ESO
# ======================================
#

# Example secret to be picked up by ESO
module "ssm_example_secret" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  create = var.enabled

  name                 = local.aws_ssm_example_secret_path
  type                 = "SecureString"
  secure_type          = true
  description          = "Example secret for cluster ${local.cluster_name}"
  ignore_value_changes = true

  value = "s3cr3t-${local.instance_name}"
}


# Tailscale
# ======================================
#
resource "tailscale_tailnet_key" "cloud_server" {
  count = var.enabled ? 1 : 0

  description   = local.instance_name
  reusable      = true
  preauthorized = true
  # Using ephemeral to have servers automatically de-register from tailscale when removed
  ephemeral = true
  tags      = local.tailscale_tags
}


# Cloudflare
# ======================================
#

# Wildcard internal DNS
# ---------------------
data "cloudflare_zone" "internal" {
  count = var.enabled ? 1 : 0

  name = var.cloudflare_internal_zone_name
}

resource "cloudflare_record" "internal_wildcard" {
  count = var.enabled ? 1 : 0

  zone_id = data.cloudflare_zone.internal[0].id
  name    = format("*.%s.%s", local.cluster_name, var.internal_dns_suffix)
  value   = format("%s.%s", local.instance_name, var.tailnet_name)
  type    = "CNAME"
  ttl     = 60
  proxied = false
  comment = "Wildcard record for environment=${var.environment}, server=${local.instance_name}"
}

# Tunnel
# ------
#
resource "random_id" "tunnel_secret" {
  count = var.enabled ? 1 : 0

  byte_length = 35
}

data "cloudflare_accounts" "main" {
  name = var.cloudflare_account_name
}

resource "cloudflare_tunnel" "tunnel" {
  count = var.enabled ? 1 : 0

  # account_id = var.cloudflare_account_id
  account_id = data.cloudflare_accounts.main.accounts[0].id
  name       = "tbnl-${local.cluster_name}"
  secret     = random_id.tunnel_secret[0].b64_std
}

# Store tunnel secret in ssm
module "ssm_tunnel_secret" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.0"

  create = var.enabled

  name                 = local.aws_ssm_tunnel_secret_path
  type                 = "SecureString"
  secure_type          = true
  description          = "Tunnel secret for cluster ${local.cluster_name}"
  ignore_value_changes = true

  value = jsonencode({
    AccountTag   = data.cloudflare_accounts.main.accounts[0].id
    TunnelID     = try(cloudflare_tunnel.tunnel[0].id, "")
    TunnelSecret = try(random_id.tunnel_secret[0].b64_std, "")
  })
}

# K3S server
# ======================================
#
module "digital_ocean_server" {
  source = "../server_digital_ocean"

  enabled = (var.enabled && var.cloud == "digital_ocean")

  name         = local.instance_name
  ssh_key_name = var.ssh_key_name
  user_data    = local.user_data
  # cloud specific settings
  instance_type = try(var.cloud_settings["instance_type"], null)
  monitoring    = try(var.cloud_settings["monitoring"], null)
}
