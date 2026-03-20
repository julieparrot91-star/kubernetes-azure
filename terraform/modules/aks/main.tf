resource "azurerm_kubernetes_cluster" "aks_cluster" {
	name = "aks_cluster"
	location = var.location
	resource_group_name = var.rg_name
	dns_prefix = "mon-cluster"

	default_node_pool {
		name           = "default-pool"
		node_count     = 1
		vm_size        = "Standard_D2s_v3"
		vnet_subnet_id = var.aks_subnet_id
	}

	identity {
		type = "SystemAssigned"
	}
}
