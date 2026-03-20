
output "aks_vnet_name" {
	description = "Virtual network name"
	value = azurerm_virtual_network.aks.name
}

output "aks_subnet_id" {
	description = "Aks subnet id"
	value = azurerm_subnet.sub_aks.id
}

output "psql_subnet_id" {
        description = "PostgreSQL subnet id"
        value = azurerm_subnet.sub_psql.id
}
