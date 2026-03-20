output "postgresql_name" {
	description = "Name of postgresql server"
	value = azurerm_postgresql_flexible_server.postgresql.name
}

output "postgresql_id" {
	description = "ID of postgresql server"
	value = azurerm_postgresql_flexible_server.postgresql.id
}
