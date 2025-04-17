resource "azurerm_postgresql_flexible_server_database" "database" {
  for_each  = toset(var.databases)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.wl_pg_server.id
}

# create an identity for each database
resource "azurerm_user_assigned_identity" "database_user" {
  for_each            = toset(var.databases)
  name                = "${azurerm_postgresql_flexible_server.wl_pg_server.name}-${each.value}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    database = each.value
  }
}

resource "azurerm_federated_identity_credential" "federated_credential" {
  for_each            = var.workload_object != null ? azurerm_user_assigned_identity.database_user : {}
  name                = "${each.value.name}-credential"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.workload_object.cluster_oidc
  parent_id           = each.value.id
  subject             = "system:serviceaccount:default:${each.value.name}"
}
