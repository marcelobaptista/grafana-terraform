#!/bin/bash

# senha do usuário admin do Grafana
admin_password="123456"
# nome do usuário admin do Grafana
admin_user="admin"
# URL do Grafana (ex: http://127.0.0.1:3000
grafana_url="http://127.0.0.1:3000"
# nome da organização
org_name="CASA"

curl -u "${admin_user}:${admin_password}" \
  "${grafana_url}/api/users?perpage=1000&page=1&sort=login-asc,email-asc" >grafana_users.json

if ! jq -e '.[].id' grafana_users.json > /dev/null 2>&1; then
  echo "Verifique o usuário e senha do Grafana"
  rm -f grafana_users.json
  exit 1
fi

mkdir -p "./${org_name}/modules/users"

cat <<EOF >"./${org_name}/modules/users/main.tf"
terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = ">= 2.5.0"
    }
  }
}
EOF

# Criação do módulo de usuários administradores do Grafana
cat <<EOF >"./${org_name}/modules/users/grafana_admins.tf"
variable "grafana_admins" {
  description = "Usuários administradores do Grafana"
  type        = list(map(string))
  default = [
EOF

length=$(jq -r '[.[] | select(.isAdmin == true)] | length ' grafana_users.json)

jq -r '[.[] | select(.isAdmin == true)] | .[] |
    "{
      name     = \"\(.name)\"
      email    = \"\(.email)\"
      login    = \"\(.login)\"
      password = \"\"
      is_admin = true
      },"' grafana_users.json >>"./${org_name}/modules/users/grafana_admins.tf"

cat <<EOF >>"./${org_name}/modules/users/grafana_admins.tf"
  ]
}

resource "grafana_user" "admins" {
  count = length(var.grafana_admins)

  email    = var.grafana_admins[count.index]["email"]
  name     = var.grafana_admins[count.index]["name"]
  login    = var.grafana_admins[count.index]["login"]
  password = var.grafana_admins[count.index]["password"]
  is_admin = var.grafana_admins[count.index]["is_admin"]
}
EOF

for ((i = 0; i < length; i++)); do
  id=$(jq -r "[.[] | select(.isAdmin == true)] | .[${i}].id" grafana_users.json)
  echo "terraform import module.users.grafana_user.admins[${i}] ${id}" >>"./${org_name}/import-${org_name}-resources.sh"
done

cat <<EOF >"./${org_name}/modules/users/grafana_viewers.tf"
variable "grafana_viewers" {
  description = "Usuários visualizadores do Grafana"
  type        = list(map(string))
  default = [
EOF

jq -r '[.[] | select(.isAdmin == false)] | .[] |
    "{
      name     = \"\(.name)\"
      email    = \"\(.email)\"
      login    = \"\(.login)\"
      password = \"\"
      is_admin = false
      },"' grafana_users.json >>"./${org_name}/modules/users/grafana_viewers.tf"

cat <<EOF >>"./${org_name}/modules/users/grafana_viewers.tf"
  ]
}

resource "grafana_user" "viewers" {
  count = length(var.grafana_viewers)

  email    = var.grafana_viewers[count.index]["email"]
  name     = var.grafana_viewers[count.index]["name"]
  login    = var.grafana_viewers[count.index]["login"]
  password = var.grafana_viewers[count.index]["password"]
  is_admin = var.grafana_viewers[count.index]["is_admin"]
}
EOF

for ((i = 0; i < length; i++)); do
  id=$(jq -r "[.[] | select(.isAdmin == false)] | .[${i}].id" grafana_users.json)
  echo "terraform import module.users.grafana_user.viewers[${i}] ${id}" >>"./${org_name}/import-${org_name}-resources.sh"
done

rm -f grafana_users.json
