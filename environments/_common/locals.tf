locals {
  project_secrets = merge(
    { for name in [
      "cloudflare",
      "cloudflare_access_email_adresses",
      "digital_ocean",
      "hetzner",
      "newrelic_api_key",
      "pushover_user_key",
      "pushover_api_key_tbnl_infra",
      "tailscale_client_id",
      "tailscale_client_secret",
      ] : name => "/${local.project}/${local.environment}/secret/${name}"
    },
    { for name in [
      "honeycomb_api_key",
      "newrelic_license_key",
      "argocd_notifications_slack_token"
      ] : name => "/${local.project}/${local.environment}/cluster-secret/${name}"
    }
  )
}
