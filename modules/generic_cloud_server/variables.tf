variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name"
}

variable "project" {
  type        = string
  default     = "tbnl-tf"
  description = "Project name, used in resource naming"
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "The gitops revision to track"
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
  description = "Ssh key to load and configure into server (cloud=digital_ocean)"
}

variable "cloudflare_account_name" {
  type        = string
  default     = "tibobeijen_main"
  description = "Cloudflare account name that holds DNS zones and tunnel configs"
}

variable "cloudflare_internal_zone_name" {
  type        = string
  default     = "tbnl.nl"
  description = "Zone to use for DNS records that are only accessible over tailnet"
}

variable "internal_dns_suffix" {
  type        = string
  default     = "internal.tbnl.nl"
  description = "All internal records will be under this domain. Needs to be within internal zone"
}

variable "tailnet_name" {
  type        = string
  default     = "greyhound-ionian.ts.net"
  description = "DNS associated with the tailne"
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

variable "external_domain" {
  type        = string
  description = "External domain name to pass to app-of-apps"
}

variable "cloud" {
  type        = string
  description = "String indicating cloud type"
  validation {
    condition     = contains(["digital_ocean"], var.cloud)
    error_message = "Cloud must be any of the supported clouds: [digital_ocean]"
  }
}
