variable "grafana_auth" {
  type      = string
  default   = ""
  sensitive = true
}

variable "grafana_url" {
  type    = string
  default = ""
}

variable "grafana_org_id" {
  type    = number
  default = 1
}