#!/bin/bash

grafana_url=
org_id=
org_name=
token_key=

cat <<EOF >"./${org_name}/modules/teams/main.tf"
terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = ">= 2.5.0"
    }
  }
}
EOF

curl -kH "Authorization: Bearer ${token_key}" "${grafana_url}/api/teams/search?" >temp.json
jq -r '.teams[] | .id' temp.json >teamIds && rm -f temp.json

while IFS= read -r teamId; do
  name=$(curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/teams/${teamId}" | jq -r '.name')
  formatted_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '-' | sed 's/&/e/g')
  email=$(curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/teams/${teamId}/members" | jq -r '.[].email')

  cat <<EOF >"./${org_name}/modules/teams/${formatted_name}.tf"
variable "${formatted_name}_name" {
  description = "Name of the team"
  default     = "${name}"
}

variable "${formatted_name}_email" {
  description = "Email of the team"
  default     = ""
}

variable "${formatted_name}_members" {
  description = "List of team members"
  type        = list(string)
  default     = [
EOF
  while IFS= read -r line; do
    echo "    \"$line\"," >>"./${org_name}/modules/teams/${formatted_name}.tf"
  done <<<"${email}"

  cat <<EOF >>"./${org_name}/modules/teams/${formatted_name}.tf"
  ]
}
EOF

  cat <<EOF >>"./${org_name}/modules/teams/${formatted_name}.tf"
    
resource "grafana_team" "${formatted_name}" {
  name    = var.${formatted_name}_name
  org_id  = "${org_id}"
  email   = var.${formatted_name}_email
  members = var.${formatted_name}_members
}
EOF
  sed -i 's/  "",//g' "./${org_name}/modules/teams/${formatted_name}.tf"
  echo "terraform import module.teams.grafana_team.${formatted_name} ${org_id}:${teamId}" >>"./${org_name}/import-${org_name}-resources.sh"
done <teamIds

rm -f teamIds
