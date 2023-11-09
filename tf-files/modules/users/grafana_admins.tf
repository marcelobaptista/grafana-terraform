variable "grafana_admins" {
  description = "Usuários administradores do Grafana"
  type        = list(map(string))
  default = [
    {
      name     = ""
      email    = "admin@localhost"
      login    = "admin"
      password = ""
      is_admin = true
    },
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
