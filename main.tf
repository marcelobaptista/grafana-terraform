terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 4.8.0"
    }
  }
}

provider "grafana" {
  auth                 = var.grafana_auth
  url                  = var.grafana_url
  org_id               = var.grafana_org_id
}
