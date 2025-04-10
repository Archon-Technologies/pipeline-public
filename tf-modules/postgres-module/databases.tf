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
