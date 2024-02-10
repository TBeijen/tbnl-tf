terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "default" {
  name = var.cf_zone_name
}

locals {
  # Specifying here to allow re-use in policy. 
  # Name used there needs to match actual name of the idp_id.
  # See: https://github.com/cloudflare/terraform-provider-cloudflare/issues/2328#issuecomment-1492031130
  github_idp_name = "GitHub"
  domain_name     = "${var.subdomain}.${var.cf_zone_name}"
}

resource "cloudflare_record" "external" {
  zone_id = data.cloudflare_zone.default.id
  name    = local.domain_name
  value   = var.tunnel_cname
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Exposing ${local.domain_name} using tunnel"
}

data "cloudflare_access_identity_provider" "github" {
  count = var.restricted ? 1 : 0

  name       = local.github_idp_name
  account_id = var.cf_account_id
}

resource "cloudflare_access_application" "app" {
  count = var.restricted ? 1 : 0

  zone_id                   = data.cloudflare_zone.default.id
  name                      = local.domain_name
  domain                    = local.domain_name
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = false
}

resource "cloudflare_access_policy" "policy" {
  count = var.restricted ? 1 : 0

  application_id = cloudflare_access_application.app[0].id
  zone_id        = data.cloudflare_zone.default.id
  name           = "Allow from GitHub"
  precedence     = "1"
  decision       = "allow"

  include {
    github {
      name                 = local.github_idp_name
      identity_provider_id = data.cloudflare_access_identity_provider.github[0].id
    }
  }
}
