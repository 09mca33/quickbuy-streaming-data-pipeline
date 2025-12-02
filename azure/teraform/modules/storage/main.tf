# ============================================
# Storage Module - ADLS Gen2
# Path: modules/storage/main.tf
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
# Storage Account (ADLS Gen2)
# ============================================

resource "azurerm_storage_account" "quickbuy" {
  name                     = "st${lower(var.project_name)}${var.environment}a${var.random_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  account_kind             = "StorageV2"
  
  # Enable ADLS Gen2
  is_hns_enabled = true
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Network rules
  network_rules {
    default_action             = "Allow" # Change to "Deny" in production
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = []
  }
  
  # Blob properties
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
  
  tags = var.tags
}

# ============================================
# Storage Containers
# ============================================

resource "azurerm_storage_container" "containers" {
  for_each = toset(var.containers)
  
  name                  = each.value
  storage_account_name  = azurerm_storage_account.quickbuy.name
  container_access_type = "private"
}

# ============================================
# Folder Structure in Containers
# ============================================

# Bronze layer folders
resource "azurerm_storage_blob" "bronze_folders" {
  for_each = toset([
    "bronze-layer/orders/",
    "bronze-layer/clickstream/",
    "bronze-layer/products/",
    "bronze-layer/customers/"
  ])
  
  name                   = each.value
  storage_account_name   = azurerm_storage_account.quickbuy.name
  storage_container_name = "bronze-layer"
  type                   = "Block"
  source_content         = ""
  
  depends_on = [azurerm_storage_container.containers]
}

# Silver layer folders
resource "azurerm_storage_blob" "silver_folders" {
  for_each = toset([
    "silver-layer/cleaned_orders/",
    "silver-layer/cleaned_clickstream/",
    "silver-layer/enriched_data/",
    "silver-layer/quality_metrics/"
  ])
  
  name                   = each.value
  storage_account_name   = azurerm_storage_account.quickbuy.name
  storage_container_name = "silver-layer"
  type                   = "Block"
  source_content         = ""
  
  depends_on = [azurerm_storage_container.containers]
}

# Gold layer folders
resource "azurerm_storage_blob" "gold_folders" {
  for_each = toset([
    "gold-layer/daily_metrics/",
    "gold-layer/customer_360/",
    "gold-layer/product_analytics/",
    "gold-layer/realtime_kpis/"
  ])
  
  name                   = each.value
  storage_account_name   = azurerm_storage_account.quickbuy.name
  storage_container_name = "gold-layer"
  type                   = "Block"
  source_content         = ""
  
  depends_on = [azurerm_storage_container.containers]
}

# ============================================
# Outputs
# ============================================

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.quickbuy.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.quickbuy.id
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.quickbuy.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.quickbuy.primary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.quickbuy.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint (ADLS Gen2)"
  value       = azurerm_storage_account.quickbuy.primary_dfs_endpoint
}

# ============================================
# Variables for this module
# Path: modules/storage/variables.tf
# ============================================

# Create a separate file: modules/storage/variables.tf

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

variable "random_suffix" {
  description = "Random suffix for unique naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "containers" {
  description = "List of containers to create"
  type        = list(string)
  default     = []
}
