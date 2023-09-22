variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Leave empty to not add a ssh key"
}