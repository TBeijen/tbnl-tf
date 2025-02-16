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

resource "newrelic_nrql_alert_condition" "synthetic" {
  policy_id                    = var.alert_policy_prio_id
  type                         = "static"
  name                         = "tbnl-${var.environment}: synthetic ${local.domain_name} failures"
  enabled                      = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT filter(count(*), WHERE result = 'FAILED') AS 'Failures' FROM SyntheticCheck WHERE monitorName IN ('${newrelic_synthetics_monitor.monitor.name}') AND NOT isMuted FACET location, monitorName"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }
  fill_option        = "none"
  aggregation_window = 60
  aggregation_method = "event_timer"
  aggregation_timer  = 60
}




# resource "newrelic_nrql_alert_condition" "pod_notready" {
#   policy_id                    = var.alert_policy_prio_id
#   type                         = "static"
#   name                         = "tbnl-${var.environment}: pod not ready"
#   enabled                      = true
#   violation_time_limit_seconds = 259200

#   nrql {
#     query = "SELECT latest(isReady) FROM K8sPodSample WHERE clusterName LIKE '${var.environment}%' AND status NOT IN ('Failed', 'Succeeded') FACET entityName"
#   }

#   critical {
#     operator              = "below"
#     threshold             = 1
#     threshold_duration    = 180
#     threshold_occurrences = "all"
#   }
#   fill_option        = "none"
#   aggregation_window = 60
#   aggregation_method = "event_flow"
#   aggregation_delay  = 120
#   title_template     = "Pod not ready"
# }
