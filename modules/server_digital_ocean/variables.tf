variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name"
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