variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name. Expected to be unique, so should contain environment and/or unique parts if applicable."
}

variable "monitoring" {
  type        = bool
  default     = true
  description = "Set to true to enable installing monitoring agent"
}

variable "instance_type" {
  type        = string
  default     = "s-1vcpu-2gb"
  description = "Droplet type"
}

variable "ssh_key_name" {
  type        = string
  default     = ""
  description = "Leave empty to not add a ssh key"
}

variable "user_data" {
  type        = string
  default     = ""
  description = "User data to bootstrap server"
}
