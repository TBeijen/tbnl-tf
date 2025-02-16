terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 3.54.0"
    }
  }
}

resource "newrelic_nrql_alert_condition" "pod_notready" {
  policy_id                    = var.alert_policy_prio_id
  type                         = "static"
  name                         = "tbnl-${var.environment}: pod not ready"
  enabled                      = true
  violation_time_limit_seconds = 259200

  nrql {
    query = "SELECT latest(isReady) FROM K8sPodSample WHERE clusterName LIKE '${var.environment}%' AND status NOT IN ('Failed', 'Succeeded') FACET entityName"
  }

  critical {
    operator              = "below"
    threshold             = 1
    threshold_duration    = 180
    threshold_occurrences = "all"
  }
  fill_option        = "none"
  aggregation_window = 60
  aggregation_method = "event_flow"
  aggregation_delay  = 120
  title_template     = "Pod not ready"
}
