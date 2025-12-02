# ============================================
# SQL Database Module
# Path: modules/sql/main.tf
# ============================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
  }
}

# ============================================
# SQL Server
# ============================================

resource "azurerm_mssql_server" "quickbuy" {
  name                         = "sql-${var.project_name}-${var.environment}-${var.location_short}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  
  minimum_tls_version = "1.2"
  
  # Azure Active Directory authentication
  azuread_administrator {
    login_username = var.sql_admin_username
    object_id      = data.azurerm_client_config.current.object_id
  }
  
  tags = var.tags
}

data "azurerm_client_config" "current" {}

# ============================================
# SQL Database
# ============================================

resource "azurerm_mssql_database" "quickbuy" {
  name           = "sqldb-${var.project_name}-products-${var.environment}"
  server_id      = azurerm_mssql_server.quickbuy.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  sku_name       = var.database_sku
  zone_redundant = false
  
  tags = var.tags
}

# ============================================
# Firewall Rules
# ============================================

# Allow Azure services to access the server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.quickbuy.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow your current IP (for initial setup)
# WARNING: Update this with your actual IP or remove in production
resource "azurerm_mssql_firewall_rule" "allow_client_ip" {
  name             = "AllowClientIP"
  server_id        = azurerm_mssql_server.quickbuy.id
  start_ip_address = "0.0.0.0"  # Replace with your IP
  end_ip_address   = "255.255.255.255"  # Replace with your IP
}

# ============================================
# Outputs
# ============================================

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.quickbuy.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.quickbuy.fully_qualified_domain_name
}

output "database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.quickbuy.name
}

output "connection_string" {
  description = "Connection string for SQL Database"
  value       = "Server=tcp:${azurerm_mssql_server.quickbuy.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.quickbuy.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

# ============================================
# Variables for this module
# Path: modules/sql/variables.tf
# ============================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "location_short" {
  description = "Short form of Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "sql_admin_username" {
  description = "Admin username for SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Admin password for SQL Server"
  type        = string
  sensitive   = true
}

variable "database_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "Basic"
}
