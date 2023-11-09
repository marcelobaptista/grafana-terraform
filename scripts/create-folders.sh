#!/bin/bash

grafana_url=
org_id=
org_name=
token_key=

cat <<EOF >>"./${org_name}/import-${org_name}-resources.sh"
#!/bin/bash

terraform init
EOF

cat <<EOF >"./${org_name}/modules/folders/main.tf"
terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = ">= 2.5.0"
    }
  }
}
EOF

chmod +x "./${org_name}/import-${org_name}-resources.sh"

curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/folders" |
  jq -r '.[].uid' >folderUIDs

while IFS= read -r folderUid; do
  curl -ksH "Authorization: Bearer ${token_key}" "${grafana_url}/api/folders/${folderUid}/permissions" |
    jq -r >temp.json
  slug=$(
    jq -r '.[0].title' temp.json |
      sed -e 's/ - / /g' -e 's/ /-/g' -e 's/\(.*\)/\L\1/' |
      tr -d '"' | tr -s '-' |
      sed -e 's/&/e/g' -e 's/@/a/g' -e 's/\///g'
  )
  folder=$(jq -cr '.[0].title' temp.json)

  cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
resource "grafana_folder" "${slug}" {
  title                        = "${folder}"
  uid                          = "${folderUid}"
  org_id                       = "${org_id}"
  prevent_destroy_if_not_empty = true
}

EOF

  team_permissions=$(
    jq -r '[.[] | select(.teamId!=0) | {teamName: .team, team: .teamId,permission: .permissionName}]' temp.json
  )
  user_permissions=$(
    jq -r '[.[] | select(.userId!=0) | {userLogin: .userLogin, userId: .userId, permission: .permissionName}]' temp.json
  )

  if [ "${team_permissions}" == "[]" ] && [ "${user_permissions}" == "[]" ]; then
    cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
resource "grafana_folder_permission" "${slug}_permissions" {
  depends_on = [grafana_folder.${slug}]
  folder_uid = grafana_folder.${slug}.uid
  org_id     = "${org_id}"

  permissions {
    role       = "Viewer"
    permission = "View"
  }

  permissions {
    role       = "Editor"
    permission = "Edit"
  }
}
EOF
  else

    length=$(jq '. | length' temp.json)

    cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
resource "grafana_folder_permission" "${slug}_permissions_users" {
  depends_on = [grafana_folder.${slug}]
  folder_uid = grafana_folder.${slug}.uid
  org_id     = "${org_id}"

  permissions {
    role       = "Viewer"
    permission = "View"
  }

  permissions {
    role       = "Editor"
    permission = "Edit"
  }

EOF

    for ((i = 0; i < length; i++)); do
      teamId=$(jq -r ".[$i].teamId" temp.json)
      teamName=$(jq -r ".[$i].team" temp.json)
      userId=$(jq -r ".[$i].userId" temp.json)
      userLogin=$(jq -r ".[$i].userLogin" temp.json)
      permission=$(jq -r ".[$i].permissionName" temp.json)

      if [ "$teamId" != "0" ]; then
        cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
  permissions {
    team_id    = "${teamId}" # ${teamName}
    permission = "${permission}"
  }

EOF
      fi
      if [ "$userId" != "0" ]; then
        cat <<EOF >>"./${org_name}/modules/folders/${slug}.tf"
  permissions {
    user_id    = "${userId}" # ${userLogin}
    permission = "${permission}"
  }

EOF
      fi
    done
    echo "}" >>"./${org_name}/modules/folders/${slug}.tf"
  fi

  echo "terraform import module.folders.grafana_folder.${slug} ${folderUid}" >>"./${org_name}/import-${org_name}-resources.sh"

done <folderUIDs

rm -rf "./${org_name}/modules/folders/*.json" folderUIDs
