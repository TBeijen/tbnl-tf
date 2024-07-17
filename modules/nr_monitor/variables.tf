variable "zone_name" {
  type        = string
  description = "Name of the DNS zone, e.g. mydomain.com"
}

variable "subdomain" {
  type        = string
  description = "Subdomain (of zone_name)"
}

variable "headers" {
  type = list(object({
    key   = string
    value = string
  }))
  default     = []
  description = "Header key value pairs"
}
