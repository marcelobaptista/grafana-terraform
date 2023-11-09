#!/bin/bash

grafana_url=
org_id=
org_name=
token_key=

cat <<EOF >"./${org_name}/modules/organizations/main.tf"
terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = ">= 2.5.0"
    }
  }
}
EOF

cat <<EOF >"./${org_name}/modules/organizations/org_admins.tf"
variable "org_admins" {
  description = "Lista de admins"
  type        = list(string)
  default = [
EOF
cat <<EOF >"./${org_name}/modules/organizations/org_editors.tf"

variable "org_editors" {
  description = "Lista de editors"
  type        = list(string)
  default = [
EOF
cat <<EOF >"./${org_name}/modules/organizations/org_viewerss.tf"

variable "org_viewers" {
  description = "Lista de viewers"
  type        = list(string)
  default = [
EOF

curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/org" | jq -r >"./${org_name}/organization.json"
curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/org/users" | jq -r >"./${org_name}/org_users.json"

name=$(jq -r '.name' "./${org_name}/organization.json")
slug=$(jq -r '.name' "./${org_name}/organization.json" |
  sed -e 's/ - / /g' -e 's/ /-/g' -e 's/\(.*\)/\L\1/' |
  tr -d '"' | tr -s '-' |
  sed -e 's/&/e/g' -e 's/@/a/g' -e 's/\///g' -e 's/\.//g')

echo "terraform import module.organizations.grafana_organization.${slug} ${org_id}" >>"./${org_name}/import-${org_name}-resources.sh"

cat <<EOF >"./${org_name}/modules/organizations/organization.tf"
resource "grafana_organization" "${slug}" {
  name         = "${name}"
  admin_user   = "admin"
  create_users = false
  admins       = var.org_admins
  editors      = var.org_editors
  viewers      = var.org_viewers
}

resource "grafana_organization_preferences" "${slug}" {
  theme      = "dark"
  timezone   = "browser"
  week_start = "Sunday"
}
EOF

length=$(jq '. | length' "./${org_name}/org_users.json")

for ((i = 0; i < length; i++)); do
  email=$(jq -r ".[$i].email" "./${org_name}/org_users.json")
  role=$(jq -r ".[$i].role" "./${org_name}/org_users.json")

  if [ "$role" == "Admin" ]; then
    echo "    \"$email"\", >>"./${org_name}/modules/organizations/org_admins.tf"
  elif [ "$role" == "Editor" ]; then
    echo "    \"$email"\", >>"./${org_name}/modules/organizations/org_editors.tf"
  else
    echo "    \"$email"\", >>"./${org_name}/modules/organizations/org_viewerss.tf"
  fi
done

cat <<EOF >>"./${org_name}/modules/organizations/org_admins.tf"
  ]
}
EOF
cat <<EOF >>"./${org_name}/modules/organizations/org_editors.tf"
  ]
}
EOF
cat <<EOF >>"./${org_name}/modules/organizations/org_viewerss.tf"
  ]
}
EOF

rm -f ./"${org_name}"/*.json
