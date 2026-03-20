resource "azurerm_resource_group" "aks" {
	name = var.rg_name
	location = var.location
}

module "postgresql" {
        source = "./modules/postgres"
        rg_name = var.rg_name
        location = var.location
        admin_password = var.admin_password
        environment   = var.environment
}

module "network" {
        source = "./modules/network"
        rg_name = var.rg_name
        location = var.location
        aks_cidr = "10.0.0.0/16"
        aks_subnet_cidr = "10.0.1.0/24"
        psql_subnet_cidr = "10.0.2.0/24"
        psql_id = module.postgresql.postgresql_id
}

module "aks-cluster" {
        source = "./modules/aks"
        rg_name = var.rg_name
        location = var.location
        aks_subnet_id = module.network.aks_subnet_id
}
