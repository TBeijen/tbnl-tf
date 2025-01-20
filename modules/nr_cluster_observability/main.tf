terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 3.54.0"
    }
  }
}

# Slack destination and channels
#
data "newrelic_notification_destination" "slack" {
  name = var.slack_notification_destination_name
}

resource "newrelic_notification_channel" "slack_prio" {
  name           = "tbnl-${var.environment}-prio-channel: ${var.slack_prio_channel.name}"
  type           = "SLACK"
  destination_id = data.newrelic_notification_destination.slack.id
  product        = "IINT"

  property {
    key           = "channelId"
    value         = var.slack_prio_channel.id
    display_value = var.slack_prio_channel.name
  }

  property {
    key   = "sendUpdatesToChannel"
    value = "true"
  }
}

# Prio policy and workflow
#
resource "newrelic_alert_policy" "prio" {
  name                = "tbnl-${var.environment}-prio-policy"
  incident_preference = "PER_POLICY"
}

resource "newrelic_workflow" "prio" {
  name                  = "tbnl-${var.environment}-prio-workflow"
  enabled               = true
  muting_rules_handling = "DONT_NOTIFY_FULLY_MUTED_ISSUES"

  issues_filter {
    name = "workflow_filter"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.prio.id]
    }
  }

  destination {
    channel_id              = newrelic_notification_channel.slack_prio.id
    notification_triggers   = ["ACKNOWLEDGED", "ACTIVATED", "CLOSED"]
    update_original_message = true
  }
}

resource "newrelic_nrql_alert_condition" "pod_notready" {
  policy_id                    = newrelic_alert_policy.prio.id
  type                         = "static"
  name                         = "tbnl-${var.environment}: pod not ready"
  enabled                      = true
  violation_time_limit_seconds = 259200


  nrql {
    query = "SELECT latest(isReady) FROM K8sPodSample WHERE clusterName LIKE 'dev%' AND status NOT IN ('Failed', 'Succeeded') FACET entityName"
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


# @TODO Review: Might not be needed, since crashloopbackoff will result in pod not ready, which is already monitored
#
# resource "newrelic_nrql_alert_condition" "pod_restarting_manually" {
#   account_id = 4355133
#   policy_id = <Your Policy ID>
#   type = "static"
#   name = "Pod restarting manually"
#   enabled = true
#   violation_time_limit_seconds = 259200

#   nrql {
#     query = "SELECT max(restartCount) - min(restartCount) AS `Restarts` FROM K8sContainerSample WHERE (((restartCount > 0) AND NOT (reason IS NULL)) AND NOT (restartCount IS NULL)) FACET tuple(containerName AS `Container Name`, podName AS `Pod Name`, clusterName AS `Cluster Name`)"
#     data_account_id = 4355133
#   }

#   critical {
#     operator = "above_or_equals"
#     threshold = 2
#     threshold_duration = 120
#     threshold_occurrences = "at_least_once"
#   }
#   fill_option = "none"
#   aggregation_window = 120
#   aggregation_method = "event_flow"
#   aggregation_delay = 120
# }
