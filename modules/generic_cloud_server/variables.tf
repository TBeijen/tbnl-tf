variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment, used in resource naming"
}

variable "add_random_pet_suffix" {
  type        = bool
  default     = true
  description = "If true, resources will have random pet name suffix"
}

variable "ssh_key_name" {
  type        = string
  default     = ""
  description = "Ssh key to load and configure into server"
}

variable "pushover_user_key" {
  type        = string
  default     = ""
  description = "User key to send PushOver notifications"
}

variable "pushover_api_token" {
  type        = string
  default     = ""
  description = "API token to send PushOver notifications"
}


variable "cloud" {
  type        = string
  description = "String indicating cloud type"
  validation {
      condition     = contains(["digital_ocean"], var.cloud)
      error_message = "Cloud must be any of the supported clouds: [digital_ocean]"
  }
}
