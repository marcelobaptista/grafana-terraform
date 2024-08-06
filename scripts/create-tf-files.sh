#!/bin/bash

admin_password=
admin_user=
grafana_url=
grafana_token=
org_name=

# Obtém a versão mais recente do Terraform Provider para Grafana
grafana_tf_version=$(
  curl -s "https://api.github.com/repos/grafana/terraform-provider-grafana/releases/latest" |
    jq -r '.tag_name | sub("^v"; "")'
)

cat <<EOF >"./${org_name}/main.tf"
terraform {
  required_providers {
    grafana = {
      source                = "grafana/grafana"
      version               = ">= ${grafana_tf_version}"
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
  auth  = "${grafana_token}"
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
