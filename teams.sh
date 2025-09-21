#!/bin/bash

# Habilita o modo de saída de erro
set -euo pipefail

# Verifica se o ambiente e o token foram passados como argumentos
if [ $# -lt 2 ]; then
  echo "Uso: $0 <grafana_url> <grafana_token>"
  exit 1
fi

# Variáveis de ambiente
grafana_url=$1
grafana_token=$2

# Consulta a API do Grafana para listar os times
curl -ksH "Authorization: Bearer ${grafana_token}" \
  "${grafana_url}/api/teams/search?" >teams.json

# IDs dos times do Grafana
jq -r '.teams[].id' teams.json >teams_ids

# Verifica se não há erro de URL e Token
if [[ ! -s teams.json || $(<teams.json) == "null" ]]; then
  echo "Verifique a URL e Token"
  rm -f teams.json
  exit 1
fi

# Cria diretório para o módulo teams
mkdir -p teams

# Cria arquivo do script de importação do Terraform
cat <<EOF >import-teams.sh
#!/bin/bash

terraform init
terraform fmt -recursive
EOF

# Adiciona o módulo teams ao arquivo principal do Terraform
cat <<EOF >>main.tf

module "teams" {
  source = "./teams"
}
EOF

# Cria arquivo principal do módulo teams
cat <<EOF >./teams/main.tf
terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = ">= 4.8.0"
    }
  }
}
EOF

while IFS= read -r team_id; do

  # Nome, email,membros e slug do time
  team_name=$(jq -r --argjson team_id "${team_id}" '.teams[] | select(.id == $team_id) | .name' teams.json)
  team_email=$(jq -r --argjson team_id "${team_id}" '.teams[] | select(.id == $team_id) | .email' teams.json)
  team_members=$(curl -ksH "Authorization: Bearer ${grafana_token}" \
    "${grafana_url}/api/teams/${team_id}/members" | jq -r '[.[].email]')
  team_name_slug=$(
    echo "${team_name}" |
      tr '[:upper:]' '[:lower:]' |
      tr -s ' ' '-' |
      sed 's/&/e/g' |
      sed 's/[^a-z0-9_-]//g'
  )

  # Cria arquivo Terraform para o time
  cat <<EOF >"./teams/${team_name_slug}.tf"
resource "grafana_team" "${team_name_slug}" {
  name        = "${team_name}"
  email       = "${team_email}"
  members     = ${team_members}
}
EOF

  # Adiciona comando de importação ao script
  echo "terraform import module.teams.grafana_team.${team_name_slug} ${team_id}" >>import-folders.sh
done <teams_ids

# Adiciona permissão de execução ao script de importação
chmod +x import-teams.sh

# Cleanup
rm -f teams_ids teams.json 