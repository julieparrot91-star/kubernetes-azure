variable "location" {
        description = "Azure Region"
        type = string
}

variable "rg_name" {
        description = "Name of the resource group"
        type = string
}

variable "aks_cidr" {
	description = "CIDR block for the aks VNET"
	type = string 
}

variable "aks_subnet_cidr" {
	description = "CIDR for the aks subnet"
	type = string
}

variable "psql_subnet_cidr" {
	description = "CIDR for the postgresql subnt"
	type = string
}

variable "psql_id" {
	description = "ID of the postgre resource"
	type = string
}
