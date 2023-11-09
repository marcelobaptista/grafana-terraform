variable "grafana_viewers" {
  description = "Usuários visualizadores do Grafana"
  type        = list(map(string))
  default = [
    {
      name     = "USER 1"
      email    = ""
      login    = "user1"
      password = "senha"
      is_admin = false
    },
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
