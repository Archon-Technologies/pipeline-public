module "shared_service_workload" {
  depends_on = [azurerm_marketplace_agreement.ubuntu]
  source     = "../../tf-modules/workload-module"

  workload_name = "bravo"
  location      = var.location
  # place this one somewhere not in the 10/8 address space
  address_space  = [cidrsubnet("10.0.0.0/8", 10, 1)]
  virtual_hub_id = data.terraform_remote_state.shared_services.outputs.virtual_hub_id

  ip_group_id = data.terraform_remote_state.shared_services.outputs.ip_group_id

  kubernetes_dns_zone = data.terraform_remote_state.shared_services.outputs.kubernetes_dns_zone
  database_dns_zone   = data.terraform_remote_state.shared_services.outputs.postgres_dns_zone
  web_dns_zone_name   = data.terraform_remote_state.shared_services.outputs.web_dns_zone_name
  web_dns_zone_rg     = data.terraform_remote_state.shared_services.outputs.web_dns_zone_rg_name

  acr_id = data.terraform_remote_state.shared_services.outputs.acr_id

  zones = [1, 2]

  should_be_autocontrolled     = true
  tfstate_storage_account_name = data.terraform_remote_state.shared_services.outputs.tfstate_storage_account_name
  tfstate_kube_container_name  = data.terraform_remote_state.shared_services.outputs.tfstate_kube_container_name
  registry_address             = data.terraform_remote_state.shared_services.outputs.registry_address

  dns_servers = [
    data.terraform_remote_state.shared_services.outputs.firewall_ip
  ]

  providers = {
    azurerm.shared_services = azurerm.shared_services,
    azurerm.networking      = azurerm.networking,
    azurerm.registration    = azurerm.registration
  }

  #   firewall_dependency = azurerm_firewall_policy_rule_collection_group.app_policy_rule_collection_group
}

module "postgres" {
  # Network connectivity needs to be established before the database can be created
  depends_on = [module.shared_service_workload]
  source     = "../../tf-modules/postgres-module"

  name     = "bravo-postgres"
  location = module.shared_service_workload.location

  private_dns_zone_id = data.terraform_remote_state.shared_services.outputs.postgres_dns_zone
  resource_group_name = module.shared_service_workload.resource_group_name

  virtual_network_name = module.shared_service_workload.virtual_network_name
  address_prefixes = [
    cidrsubnet(module.shared_service_workload.address_space[0], 4, 1),
  ]

  databases = [
    "govdash"
  ]

  workload_object = module.shared_service_workload
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "ad_admin" {
  server_name         = module.postgres.name
  object_id           = data.azurerm_client_config.current.object_id
  resource_group_name = module.shared_service_workload.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  principal_name      = "postgres-admin"
  principal_type      = "ServicePrincipal"
}
