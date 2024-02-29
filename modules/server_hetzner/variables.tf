variable "enabled" {
  type        = bool
  default     = true
  description = "If true, resources will be created"
}

variable "name" {
  type        = string
  description = "Server name. Expected to be unique, so should contain environment and/or unique parts if applicable."
}

variable "instance_type" {
  type        = string
  description = "Server type"
}

variable "ssh_key_name" {
  type        = string
  default     = "tbnl_ed25519_2022"
  description = "Key that will be used (set manually in console)"
}

variable "user_data" {
  type        = string
  default     = ""
  description = "User data to bootstrap server"
}
