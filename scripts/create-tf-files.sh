#!/bin/bash

admin_password=
admin_user=
grafana_url=
org_name=
token_key=

cat <<EOF >"./${org_name}/providers.tf"
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
  url   = "${grafana_url}"
  auth  = "${admin_user}:${admin_password}"
}

provider "grafana" {
  alias = "token"
  url   = "${grafana_url}"
  auth  = "${token_key}"
}
EOF

cat <<EOF >"./${org_name}/modules.tf"
module "organizations" {
  source     = "./modules/organizations"
  providers = {
    grafana = grafana.basic
  }
}

module "teams" {
  source     = "./modules/teams"
  depends_on = [module.organizations]
  providers = {
    grafana = grafana.token
  }
}

module "folders" {
  source     = "./modules/folders"
  depends_on = [module.teams]
  providers = {
    grafana = grafana.token
  }
}
EOF
