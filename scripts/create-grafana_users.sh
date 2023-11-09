#!/bin/bash

# senha do usuário admin do Grafana
admin_password="123456"
# nome do usuário admin do Grafana
admin_user="admin"
# URL do Grafana (ex: http://127.0.0.1:3000
grafana_url="http://127.0.0.1:3000"
# nome da organização
org_name="CASA"

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

cat <<EOF >"./${org_name}/modules/users/grafana_admins.tf"
variable "grafana_admins" {
  description = "Usuários administradores do Grafana"
  type        = list(map(string))
  default = [
EOF

cat <<EOF >"./${org_name}/modules/users/grafana_viewers.tf"
variable "grafana_viewers" {
  description = "Usuários visualizadores do Grafana"
  type        = list(map(string))
  default = [
EOF

curl -u "${admin_user}:${admin_password}" "${grafana_url}/api/users?perpage=1000&page=1&sort=login-asc,email-asc" >grafana_users.json
length=$(jq '. | length' "./grafana_users.json")

j=0
k=0
for ((i = 0; i < length; i++)); do
  login=$(jq -r ".[$i].login" "./grafana_users.json")
  email=$(jq -r ".[$i].email" "./grafana_users.json")
  name=$(jq -r ".[$i].name" "./grafana_users.json")
  id=$(jq -r ".[$i].id" "./grafana_users.json")
  isAdmin=$(jq -r ".[$i].isAdmin" "./grafana_users.json")

  if [ "${isAdmin}" == "true" ]; then
    cat <<EOF >>"./${org_name}/modules/users/grafana_admins.tf"
    {
      name     = "${name}"
      email    = "${email}"
      login    = "${login}"
      password = ""
      is_admin = true
    },
EOF
    echo "terraform import module.users.grafana_user.admins[$j] ${id}" >>"./${org_name}/import-${org_name}-resources.sh"
    ((j++))
  else
    cat <<EOF >>"./${org_name}/modules/users/grafana_viewers.tf"
    {
      name     = "${name}"
      email    = "${email}"
      login    = "${login}"
      password = ""
      is_admin = false
    },
EOF
    echo "terraform import module.users.grafana_user.viewers[$k] ${id}" >>"./${org_name}/import-${org_name}-resources.sh"
    ((k++))
  fi
done
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
rm -f grafana_users.json
