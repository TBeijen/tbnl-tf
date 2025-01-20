terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 3.54.0"
    }
  }
}

locals {
  domain_name = "${var.subdomain}.${var.zone_name}"
  headers = concat(
    var.headers,
    [
      {
        key   = "health-check"
        value = "true"
      }
    ]
  )
}

resource "newrelic_synthetics_monitor" "monitor" {
  status = "ENABLED"
  name   = local.domain_name
  period = "EVERY_MINUTE"
  uri    = "https://${local.domain_name}${var.uri}"
  type   = "SIMPLE"
  locations_public = [
    "EU_CENTRAL_1",
    "EU_WEST_1",
    "US_EAST_2",
  ]

  dynamic "custom_header" {

    for_each = local.headers
    content {
      name  = custom_header.value.key
      value = custom_header.value.value
    }
  }

  treat_redirect_as_failure = true
  bypass_head_request       = true
  verify_ssl                = true

  tag {
    key    = "environment"
    values = [var.environment]
  }
}
