module "organizations" {
  source     = "./modules/organizations"
  depends_on = [module.users]
  providers = {
    grafana = grafana.basic
  }
}

module "teams" {
  source     = "./modules/teams"
  depends_on = [module.organizations, module.users]
  providers = {
    grafana = grafana.token
  }
}

module "folders" {
  source     = "./modules/folders"
  depends_on = [module.users, module.teams]
  providers = {
    grafana = grafana.token
  }
}

module "users" {
  source = "./modules/users"
  providers = {
    grafana = grafana.basic
  }
}
