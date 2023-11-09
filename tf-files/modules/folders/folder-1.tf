resource "grafana_folder" "folder-1" {
  title                        = "FOLDER 1"
  org_id                       = "1"
  prevent_destroy_if_not_empty = true
}

resource "grafana_folder_permission" "folder-1_permissions_users" {
  depends_on = [grafana_folder.folder-1]
  folder_uid = grafana_folder.folder-1.uid
  org_id     = "1"

  permissions {
    role       = "Viewer"
    permission = "View"
  }

  permissions {
    role       = "Editor"
    permission = "Edit"
  }

  permissions {
    user_id    = "1" # admin
    permission = "Admin"
  }

  permissions {
    team_id    = "1" # TEAM 1
    permission = "Admin"
  }

}
