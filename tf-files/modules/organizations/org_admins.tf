variable "org_admins" {
  description = "Lista de admins"
  type        = list(string)
  default = [
    "admin@localhost",
  ]
}
