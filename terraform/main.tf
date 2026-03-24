resource "azurerm_resource_group" "aks" {
	name = var.rg_name
	location = var.location
}

# module "postgresql" {
#         source = "./modules/postgres"
#         rg_name = var.rg_name
#         location = var.location
#         admin_password = var.admin_password
#         environment   = var.environment
# }

resource "azurerm_postgresql_flexible_server" "postgresql" {
	name = "psql-jul24"
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
	public_network_access_enabled = true
}

output "psql_id" {
	value = azurerm_postgresql_flexible_server.postgresql.id
}

module "network" {
        source = "./modules/network"
        rg_name = var.rg_name
        location = var.location
        aks_cidr = "10.0.0.0/16"
        aks_subnet_cidr = "10.0.1.0/24"
        psql_subnet_cidr = "10.0.2.0/24"
        psql_id = azurerm_postgresql_flexible_server.postgresql.id
}

module "acr" {
        source = "./modules/acr"
        rg_name = var.rg_name
        location = var.location
        environment = var.environment
}

module "aks-cluster" {
        source = "./modules/aks"
        rg_name = var.rg_name
        location = var.location
        aks_subnet_id = module.network.aks_subnet_id
        acr_id = module.acr.acr_id
}
