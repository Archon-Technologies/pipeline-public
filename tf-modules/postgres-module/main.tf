data "azurerm_client_config" "current" {}

resource "azurerm_subnet" "database_subnet" {
  name                            = "shared-services-database-subnet"
  default_outbound_access_enabled = false
  resource_group_name             = var.resource_group_name
  virtual_network_name            = var.virtual_network_name
  address_prefixes                = var.address_prefixes
  service_endpoints = [
    "Microsoft.Storage"
  ]
  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# TODO: make me HA!!!
resource "azurerm_postgresql_flexible_server" "wl_pg_server" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "B_Standard_B1ms"
  version  = "16"

  identity {
    type = "SystemAssigned"
  }

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  storage_mb                   = 32768
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = azurerm_subnet.database_subnet.id
  private_dns_zone_id = var.private_dns_zone_id

  public_network_access_enabled = false

  zone = var.zone
}

resource "azurerm_network_security_group" "database_nsg" {
  # allow the node space and the workload space to talk to the database
  count               = var.workload_object != null ? 1 : 0
  name                = "${var.name}-database-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name        = "allow-aks"
    description = "Allow access to Postgres from the AKS nodes"
    priority    = 100
    direction   = "Inbound"
    source_address_prefixes = [
      cidrsubnet(var.workload_object.address_space[0], 4, 0),
    ]
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "5432"
    access                     = "Allow"
    protocol                   = "Tcp"
  }
}

resource "azurerm_subnet_network_security_group_association" "database_nsg" {
  count                     = var.workload_object != null ? 1 : 0
  subnet_id                 = azurerm_subnet.database_subnet.id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}
