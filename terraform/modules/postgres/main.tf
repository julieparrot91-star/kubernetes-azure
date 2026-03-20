resource "azurerm_postgresql_flexible_server" "postgresql" {
	name = "psql-${var.environment}"
	location = var.location
	resource_group_name = var.rg_name

	administrator_login    = "psqladmin"
	administrator_password = var.admin_password

	sku_name = "B_Standard_B1ms"
	version  = "15"
	storage_mb = 32768

	backup_retention_days = 7
	geo_redundant_backup_enabled = false
	auto_grow_enabled = true
}
