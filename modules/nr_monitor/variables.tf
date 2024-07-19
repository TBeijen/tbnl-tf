variable "zone_name" {
  type        = string
  description = "Name of the DNS zone, e.g. mydomain.com"
}

variable "subdomain" {
  type        = string
  description = "Subdomain (of zone_name)"
}

variable "environment" {
  type        = string
  description = "Environment. Will be added to tags"
}

variable "uri" {
  type        = string
  default     = "/"
  description = "Uri to fetch"
}

variable "status" {
  type        = string
  default     = "ENABLED"
  description = "Monitor status (set to DISABLED if no server active for environment)"
}

variable "headers" {
  type = list(object({
    key   = string
    value = string
  }))
  default     = []
  description = "Header key value pairs"
}
