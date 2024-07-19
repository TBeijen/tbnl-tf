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
  domain_name = "${var.subdomain}.${var.cf_zone_name}"
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

resource "cloudflare_access_application" "app" {
  count = var.restricted ? 1 : 0

  zone_id                   = data.cloudflare_zone.default.id
  name                      = local.domain_name
  domain                    = local.domain_name
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = false
}

resource "cloudflare_access_policy" "default" {
  count = var.restricted ? 1 : 0

  application_id = cloudflare_access_application.app[0].id
  zone_id        = data.cloudflare_zone.default.id
  name           = "Allow from GitHub"
  precedence     = "1"
  decision       = "allow"

  include {
    group = var.cf_access_groups
  }
}

# Best would be to create a separate application, restricted to the health check path.
# Then only for that application, allow the access group that includes the non-identity service token.
#
# Since the service token ends up in monitor configuration, this reduces the impact of the token accidentally being exposed.
resource "cloudflare_access_policy" "health" {
  count = var.restricted ? 1 : 0

  application_id = cloudflare_access_application.app[0].id
  zone_id        = data.cloudflare_zone.default.id
  name           = "Allow from health check"
  precedence     = "2"
  decision       = "non_identity"

  include {
    group = var.cf_access_groups_health
  }
}
