variable "project" {
  type        = string
  default     = "tbnl-tf"
  description = "Project name to use in resource naming"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment, used in resource naming"
}

variable "state_bucket" {
  type        = string
  description = "State bucket to create on first apply (using --target)"
}

variable "state_dynamodb_table" {
  type        = string
  description = "State dynamodb table to create on first apply (using --target)"
}

variable "project_secrets" {
  type        = map(any)
  description = "SSM secrets to provision and load"
}

variable "cloud_servers" {
  type = map(object({
    enabled = bool
    cloud   = string
  }))
  validation {
    condition     = toset(keys(var.cloud_servers)) == toset(["blue", "green"])
    error_message = "Var cloud_servers must define a 'blue' and 'green' object"
  }

}

variable "do_provision_ssh_key" {
  type        = bool
  default     = false
  description = "If true, key will be provisioned. Only one identical key can exist."
}
