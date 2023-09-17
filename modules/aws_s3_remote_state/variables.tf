variable "project" {
  type        = string
  default     = "my-project"
  description = "Project name to use in resource naming"
}

variable "environment" {
  type        = string
  default     = "test"
  description = "Environment, used in resource naming"
}