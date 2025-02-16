variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment. Used in naming."
}

variable "slack_notification_destination_name" {
  type        = string
  default     = "slack"
  description = "Name of the slack notification destination"
}

variable "slack_prio_channel" {
  type = object({
    id   = string
    name = string
  })
  description = "Channel to use for priority notifications. Adjusted according to env."
}

variable "slack_noise_channel" {
  type = object({
    id   = string
    name = string
  })
  description = "Channel to use for less important notifications. Adjusted according to env."
}
