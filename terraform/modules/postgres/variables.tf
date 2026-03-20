variable "location" {
	description = "Azure Region"
	type = string
}

variable "rg_name" {
	description = "Name of the resource group"
	type = string
}

variable "admin_password" {
	description = "Admin password"
	type        = string
}

variable "environment" {
	description = "Environment name (dev, prod)"
	type        = string
	default     = "dev"
}
