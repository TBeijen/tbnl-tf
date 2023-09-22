variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name"
}

variable "add_random_pet_suffix" {
  type        = bool
  default     = true
  description = "If true, resources will have random pet name suffix"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Leave empty to not add a ssh key"
}

variable "cloud" {
  type        = string
  description = "String indicating cloud type"
  validation {
      condition     = contains(["digital_ocean"], var.cloud)
      error_message = "Cloud must be any of the supported clouds: [digital_ocean]"
  }
}
