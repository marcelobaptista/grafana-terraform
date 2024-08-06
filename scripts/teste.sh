#!/bin/bash

# Variáveis para URL e Token do Grafana
grafana_url="http://127.0.0.1:3000"
grafana_token=
org_id=1
org_name=CASA

# Obtém a versão mais recente do Terraform Provider para Grafana
grafana_tf_version=$(
  curl -s "https://api.github.com/repos/grafana/terraform-provider-grafana/releases/latest" |
    jq -r '.tag_name | sub("^v"; "")'
)

# Obtém os UIDs das pastas do Grafana
curl -ksH "Authorization: Bearer ${grafana_token}" \
  "${grafana_url}/api/folders" |
  jq -r '.[].uid' >folderUIDs

# Verifica se os UIDs foram obtidos corretamente
if [[ ! -s folderUIDs || $(<folderUIDs) == "null" ]]; then
  echo "Verifique a URL e Token"
  exit 1
fi

# Cria script de importação
cat <<EOF >"./${org_name}/import-${org_name}-resources.sh"
#!/bin/bash

terraform init
EOF

# Cria arquivo principal do Terraform
cat <<EOF >"./${org_name}/modules/folders/main.tf"
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= ${grafana_tf_version}"
    }
  }
}
EOF

#
while IFS= read -r folderUid; do
  # Obtém permissões da pasta
  curl -ksH "Authorization: Bearer ${grafana_token}" \
    "${grafana_url}/api/folders/${folderUid}/permissions" |
    jq -r >./folder.json

  # Extrai slug e título da pasta
  slug=$(jq -cr '.[0].slug' ./folder.json)
  title=$(jq -cr '.[0].title' ./folder.json)

  # Cria arquivo Terraform para a pasta
  cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
resource "grafana_folder" "${slug}" {
  title                        = "${title}"
  uid                          = "${folderUid}"
  org_id                       = "${org_id}"
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "${slug}_permissions" {
  depends_on = [grafana_folder.${slug}]
  folder_uid = grafana_folder.${slug}.uid
  permissions {
    role       = "Viewer"
    permission = "View"
  }
  permissions {
    role       = "Editor"
    permission = "Edit"
  }
EOF

  #
  jq -r '
  [.[] | 
  select((.teamId!=0 and .userId==0) 
  or (.teamId==0 and .userId!=0))] |
  .[] | 
  "  permissions {
     user_id       = \"\(.userId)\" # \(.userLogin)
     team_id       = \"\(.teamId)\" # \(.team)
     permission    = \"\(.permissionName)\" 
  }"' ./folder.json >>"./${org_name}/modules/folders/${slug}.tf"
  # Fecha arquivo Terraform
  echo "}" >>"./${org_name}/modules/folders/${slug}.tf"

  # Cleanup
  rm -f ./folder.json
done <folderUIDs

# Adiciona permissões de execução ao script de importação
chmod +x "./${org_name}/import-${org_name}-resources.sh"

# Cleanup
rm ./folderUIDs
