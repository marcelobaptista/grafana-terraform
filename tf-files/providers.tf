terraform {
  required_providers {
    grafana = {
      source                = "grafana/grafana"
      version               = ">= 2.5.0"
      configuration_aliases = [grafana.basic, grafana.token]
    }
  }
}

provider "grafana" {
  alias = "basic"
  url   = "http://127.0.0.1:3000"
  auth  = "admin:123456"
}

provider "grafana" {
  alias = "token"
  url   = "http://127.0.0.1:3000"
  auth  = ""
}
