resource "azurerm_kubernetes_cluster" "aks_cluster" {
	name = "aks_cluster"
	location = var.location
	resource_group_name = var.rg_name
	dns_prefix = "mon-cluster"

	network_profile {
		network_plugin     = "azure"
		service_cidr       = "10.1.0.0/16"
		dns_service_ip    = "10.1.0.10"
	}

	default_node_pool {
		name           = "defaultpool"
		node_count     = 1
		vm_size        = "Standard_D2s_v3"
		vnet_subnet_id = var.aks_subnet_id
	}

	identity {
		type = "SystemAssigned"
	}
}

resource "azurerm_role_assignment" "aks_to_acr" {
	principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
	role_definition_name = "AcrPull"
	scope                = var.acr_id
}
