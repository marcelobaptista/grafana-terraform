resource "grafana_organization" "main-org" {
  name         = "Main Org."
  admin_user   = "admin"
  create_users = false
  admins       = var.org_admins
  editors      = var.org_editors
  viewers      = var.org_viewers
}

resource "grafana_organization_preferences" "main-org" {
  theme      = "dark"
  timezone   = "browser"
  week_start = "Sunday"
}
