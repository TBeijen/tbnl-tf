variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment. Used in naming."
}

variable "alert_policy_prio_id" {
  type        = string
  description = "ID of the alert policy for priority alerts"
}

variable "alert_policy_noise_id" {
  type        = string
  description = "ID of the alert policy for noise alerts"
}
