variable "team-1_name" {
  description = "Name of the team"
  default     = "TEAM 1"
}

variable "team-1_email" {
  description = "Email of the team"
  default     = ""
}

variable "team-1_members" {
  description = "List of team members"
  type        = list(string)
  default = [
    "user1",
    "admin@localhost",
  ]
}

resource "grafana_team" "team-1" {
  name    = var.team-1_name
  org_id  = "1"
  email   = var.team-1_email
  members = var.team-1_members
}
