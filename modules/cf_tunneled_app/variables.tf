variable "cf_zone_name" {
  type        = string
  description = "Name of the cloudflare zone, e.g. mydomain.com"
}

variable "cf_access_groups" {
  type        = list(string)
  description = "List of access group ids to grant access to restricted apps"
}

variable "tunnel_cname" {
  type        = string
  description = "Cname of the cloudflare tunnel that should be used for the subdomain"
}

variable "subdomain" {
  type        = string
  description = "Subdomain (of zone_name)"
}

variable "restricted" {
  type        = bool
  default     = false
  description = "If true, cloudflare access will be set up for the subdomain"
}
