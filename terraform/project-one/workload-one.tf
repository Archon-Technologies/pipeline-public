module "shared_service_workload" {
  source = "../../tf-modules/workload-module"

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

  zones = [2, 3]

  dns_servers = [
    data.terraform_remote_state.shared_services.outputs.firewall_ip
  ]

  providers = {
    azurerm.shared_services = azurerm.shared_services,
    azurerm.networking      = azurerm.networking
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
}

resource "azurerm_federated_identity_credential" "federated_credential" {
  for_each            = module.postgres.created_identities
  name                = "${each.value.name}-credential"
  resource_group_name = module.shared_service_workload.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.shared_service_workload.cluster_oidc
  parent_id           = each.value.id
  subject             = "system:serviceaccount:default:${each.value.name}"
}

resource "azurerm_network_security_group" "database_nsg" {
  # allow the node space and the workload space to talk to the database
  name                = "wl-bravo-database-nsg"
  location            = module.shared_service_workload.location
  resource_group_name = module.shared_service_workload.resource_group_name
  security_rule {
    name        = "allow-aks"
    description = "Allow access to Postgres from the AKS nodes"
    priority    = 100
    direction   = "Inbound"
    source_address_prefixes = [
      cidrsubnet(module.shared_service_workload.address_space[0], 4, 0),
    ]
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "5432"
    access                     = "Allow"
    protocol                   = "Tcp"
  }
}

resource "azurerm_subnet_network_security_group_association" "database_nsg" {
  subnet_id                 = module.postgres.subnet_id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "ad_admin" {
  server_name         = module.postgres.name
  object_id           = data.azurerm_client_config.current.object_id
  resource_group_name = module.shared_service_workload.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  principal_name      = "postgres-admin"
  principal_type      = "ServicePrincipal"
}

output "db_identity_client_id" {
  value = module.postgres.created_identities.test.client_id
}

output "dns_identity_client_id" {
  value = module.shared_service_workload.dns_identity_client_id
}

output "dns_identity_resource_group" {
  value = data.terraform_remote_state.shared_services.outputs.web_dns_zone_rg_name
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
