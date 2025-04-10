output "name" {
  description = "Name of the database"
  value       = azurerm_postgresql_flexible_server.wl_pg_server.name

}

output "id" {
  description = "The id of the database"
  value       = azurerm_postgresql_flexible_server.wl_pg_server.id
}

output "subnet_id" {
  description = "The id of the subnet the database is in"
  value       = azurerm_subnet.database_subnet.id
}

output "created_identities" {
  value       = azurerm_user_assigned_identity.database_user
  description = "The identities created for each database"
}
