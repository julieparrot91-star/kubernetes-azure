resource "azurerm_virtual_network" "aks" {
	name = "aks-vnet"
	address_space = [var.aks_cidr]
	location = var.location
	resource_group_name = var.rg_name
	
}

resource "azurerm_subnet" "sub_aks" {
	name = "AksSubnet"
	resource_group_name = var.rg_name
	virtual_network_name = azurerm_virtual_network.aks.name
	address_prefixes = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "sub_psql" {
        name = "PsqlSubnet"
        resource_group_name = var.rg_name
        virtual_network_name = azurerm_virtual_network.aks.name
        address_prefixes = [var.psql_subnet_cidr]
	service_endpoints = ["Microsoft.Sql"]
}

resource "azurerm_private_endpoint" "psql_endpoint" {
	name = "PrivateEndpointPSQL"
	location = azurerm_virtual_network.aks.location
	resource_group_name = azurerm_virtual_network.aks.resource_group_name
	subnet_id = azurerm_subnet.sub_psql.id

	private_service_connection {
		name = "psql-privateserviceconnection"
		private_connection_resource_id = var.psql_id
		subresource_names = ["postgresqlServer"]
		is_manual_connection = false	
	}
	
}
