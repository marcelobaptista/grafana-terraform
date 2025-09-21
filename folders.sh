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

# Consulta a API do Grafana para listar as pastas
curl -ksH "Authorization: Bearer ${grafana_token}" \
  "${grafana_url}/api/search?query=&type=dash-folder" | jq -r >folders.json

# Verifica se não há erro de URL e Token
if [[ ! -s folders.json || $(<folders.json) == "null" ]]; then
  echo "Verifique a URL e Token"
  rm -f folders.json
  exit 1
fi

# Cria diretório para o módulo folders
mkdir -p folders

# UIDs das pastas do Grafana
jq -r '.[].uid' folders.json >folder_uids

# Cria arquivo do script de importação do Terraform
cat <<EOF >import-folders.sh
#!/bin/bash

terraform init
terraform fmt -recursive
EOF

# Adiciona o módulo folders ao arquivo principal do Terraform
cat <<EOF >>main.tf

module "folders" {
  source = "./folders"
}
EOF

# Cria arquivo principal do módulo folders
cat <<EOF >./folders/main.tf
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 4.8.0"
    }
  }
}
EOF

# Cria arquivos .tf para cada pasta e suas permissões
while IFS= read -r folder_uid; do

  # Variável que verifica se é uma subpasta
  parent_folder=$(jq -r --arg folder_uid "${folder_uid}" '.[] | select(.uid == $folder_uid) | .folderUid' folders.json)

  # Nome e slug da pasta
  title=$(jq -r --arg folder_uid "${folder_uid}" '.[] | select(.uid == $folder_uid) | .title' folders.json)
  slug=$(jq -r --arg folder_uid "${folder_uid}" '.[] | select(.uid == $folder_uid) | .uri' folders.json | awk -F'db/' '{print $2}')

  # Consulta a API para verificar permissões da pasta
  curl -ksH "Authorization: Bearer ${grafana_token}" \
    "${grafana_url}/api/folders/${folder_uid}/permissions" |
    jq -r >folder.json

  # Verifica se a pasta é uma subpasta
  if [[ -n "${parent_folder}" && "${parent_folder}" != "null" ]]; then

    # Cria arquivo Terraform para a subpasta
    cat <<EOF >"./folders/${slug}.tf"
resource "grafana_folder" "${slug}" {
  title                        = "${title}"
  uid                          = "${folder_uid}"
  parent_folder_uid            = "${parent_folder}"
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "${slug}" {
  folder_uid = grafana_folder.${slug}.uid
EOF
  else

    # Cria arquivo Terraform para a pasta com as permissões padrão
    cat <<EOF >"./folders/${slug}.tf"
resource "grafana_folder" "${slug}" {
  title                        = "${title}"
  uid                          = "${folder_uid}"
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "${slug}" {
  folder_uid = grafana_folder.${slug}.uid
EOF
  fi

  # Adiciona permissões da pasta ao arquivo Terraform
  {
    # Verifica permissões por role
    jq -r '
    [.[] | select((.teamId==0 and .userId==0))] | .[] | 

    "permissions {
      role       = \"\(.role)\"
      permission = \"\(.permissionName)\"
    }"' folder.json

    # Verifica permissões por time
    jq -r '
    [.[] | select((.teamId!=0 and .userId==0))] | .[] |

    "permissions {
      team_id       = \"\(.teamId)\" # \(.team)
      permission    = \"\(.permissionName)\" 
    }"' folder.json

    # Verifica permissões por usuário
    jq -r '
    [.[] | select((.teamId==0 and .userId!=0))] | .[] |
    
    "permissions {
      user_id       = \"\(.userId)\" # \(.userLogin)
      permission    = \"\(.permissionName)\" 
    }"' folder.json

  } >>"./folders/${slug}.tf"

  # Fecha o arquivo Terraform
  echo "}" >>"./folders/${slug}.tf"

  # Adiciona comandos de importação ao script
  echo "terraform import module.folders.grafana_folder.${slug} ${folder_uid}" >>import-folders.sh
  echo "terraform import module.folders.grafana_folder_permission.${slug} ${folder_uid}" >>import-folders.sh
done <folder_uids

# Adiciona permissão de execução ao script de importação
chmod +x import-folders.sh

# Cleanup
rm -f folder.json folders.json folder_uids
