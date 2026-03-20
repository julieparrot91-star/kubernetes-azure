variable "location" {
        description = "Azure region"
        type        = string
        default     = "West Europe"
}

variable "rg_name" {
        description = "Name of the resource group"
        type        = string
}

variable "admin_password" {
     description = "PostgreSQL admin password"
     type        = string
     sensitive   = true 
}

variable "environment" {
     description = "Environment name (dev, prod)"
     type        = string
     default     = "dev"
}
