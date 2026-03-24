variable "location" {
        description = "Azure region"
        type = string
}

variable "rg_name" {
        description = "Aks resource group name"
        type = string
}

variable "aks_subnet_id" {
	description = "Aks subnet ID"
	type = string
}

variable "acr_id" {
	description = "ACR ID for pull access"
	type        = string
}
