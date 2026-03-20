output "aks_cluster_name" {
	description = "Name of the aks cluster"
	value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "client_certificate" {
	description = "Certificate of the client"
	value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
	sensitive = true
}

output "kube_config" {
	value = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
	sensitive = true
}


