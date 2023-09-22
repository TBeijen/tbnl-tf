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
  description = "If true, resources will have random pet name suffix"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Leave empty to not add a ssh key"
}