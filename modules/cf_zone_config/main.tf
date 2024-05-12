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

# Cache rule configuring cache settings and defining custom cache keys
resource "cloudflare_ruleset" "cache_rules_everything" {
  zone_id = data.cloudflare_zone.default.id

  name        = "Domain defaults"
  description = "Default cache settings: Enabled for all content."
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules {
    action = "set_cache_settings"
    action_parameters {
      edge_ttl {
        # Let response headers control cache ttl
        mode = "respect_origin"
      }
      browser_ttl {
        # Be nice for visitors by allowing browser to cache
        # Consider change into respect_origin when fixed nginx config 
        # to distinguish max-age for html (short) and images and assets (longer)
        mode    = "override_origin"
        default = "3600"
      }
      serve_stale {
        disable_stale_while_updating = false
      }
      respect_strong_etags = false

      cache_key {
        ignore_query_strings_order = true
      }
      origin_error_page_passthru = false
    }

    expression  = "(starts_with(http.request.uri, \"/\"))"
    description = "Cache everything (also HTML)"
    enabled     = true
  }
}
