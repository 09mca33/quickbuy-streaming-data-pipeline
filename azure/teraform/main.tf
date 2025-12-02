# ============================================
# QuickBuy Streaming Data Pipeline
# Main Terraform Configuration
# ============================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
  
  # Uncomment for remote state (recommended for team collaboration)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstatequickbuy"
  #   container_name       = "tfstate"
  #   key                  = "quickbuy.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ============================================
# Local Variables
# ============================================

locals {
  project_name   = var.project_name
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
  
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Project      = local.project_name
      Environment  = local.environment
      ManagedBy    = "Terraform"
      Repository   = "github.com/${var.github_username}/quickbuy-streaming-data-pipeline"
      CreatedDate  = timestamp()
    }
  )
  
  # Resource naming convention
  resource_group_name = "rg-${lower(local.project_name)}-${local.environment}-${local.location_short}"
}

# ============================================
# Random Suffix for Globally Unique Names
# ============================================

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# ============================================
# Resource Group
# ============================================

resource "azurerm_resource_group" "quickbuy" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# ============================================
# Module: Storage Account (ADLS Gen2)
# ============================================

module "storage" {
  source = "./modules/storage"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  random_suffix       = random_string.suffix.result
  tags                = local.common_tags
  
  containers = [
    "bronze-layer",
    "silver-layer",
    "gold-layer",
    "checkpoints",
    "configs",
    "logs",
    "archive",
    "temp"
  ]
}

# ============================================
# Module: Event Hubs
# ============================================

module "eventhubs" {
  source = "./modules/eventhubs"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  tags                = local.common_tags
  
  namespace_sku      = var.eventhubs_sku
  namespace_capacity = var.eventhubs_capacity
  
  event_hubs = {
    orders = {
      partition_count   = 4
      message_retention = 7
      consumer_groups   = ["databricks-bronze", "databricks-silver", "monitoring"]
    }
    clickstream = {
      partition_count   = 8
      message_retention = 3
      consumer_groups   = ["databricks-bronze", "analytics"]
    }
    products = {
      partition_count   = 2
      message_retention = 7
      consumer_groups   = ["databricks-cdc"]
    }
  }
}

# ============================================
# Module: Key Vault
# ============================================

module "keyvault" {
  source = "./modules/keyvault"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  random_suffix       = random_string.suffix.result
  tags                = local.common_tags
  
  # Pass secrets to store
  secrets = {
    storage-account-key                      = module.storage.primary_access_key
    storage-connection-string                = module.storage.primary_connection_string
    eventhub-orders-connection-string        = module.eventhubs.orders_connection_string
    eventhub-clickstream-connection-string   = module.eventhubs.clickstream_connection_string
    eventhub-products-connection-string      = module.eventhubs.products_connection_string
  }
}

# ============================================
# Module: Databricks Workspace
# ============================================

module "databricks" {
  source = "./modules/databricks"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  tags                = local.common_tags
  
  sku                         = "premium"
  storage_account_name        = module.storage.storage_account_name
  storage_account_id          = module.storage.storage_account_id
  storage_primary_dfs_endpoint = module.storage.primary_dfs_endpoint
}

# ============================================
# Module: Azure SQL Database (Optional)
# ============================================

module "sql_database" {
  source = "./modules/sql"
  count  = var.create_sql_database ? 1 : 0
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  tags                = local.common_tags
  
  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password
  database_sku       = var.sql_database_sku
}

# ============================================
# Module: Monitoring & Logging
# ============================================

module "monitoring" {
  source = "./modules/monitoring"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = azurerm_resource_group.quickbuy.name
  tags                = local.common_tags
  
  retention_days = var.log_retention_days
}

# ============================================
# Outputs
# ============================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.quickbuy.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_key" {
  description = "Primary access key for storage account"
  value       = module.storage.primary_access_key
  sensitive   = true
}

output "databricks_workspace_url" {
  description = "URL of the Databricks workspace"
  value       = module.databricks.workspace_url
}

output "databricks_workspace_id" {
  description = "ID of the Databricks workspace"
  value       = module.databricks.workspace_id
}

output "eventhubs_namespace_name" {
  description = "Name of the Event Hubs namespace"
  value       = module.eventhubs.namespace_name
}

output "eventhubs_connection_strings" {
  description = "Connection strings for Event Hubs"
  value = {
    orders      = module.eventhubs.orders_connection_string
    clickstream = module.eventhubs.clickstream_connection_string
    products    = module.eventhubs.products_connection_string
  }
  sensitive = true
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

# SQL Database outputs (if created)
output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = var.create_sql_database ? module.sql_database[0].sql_server_fqdn : null
}

output "sql_database_name" {
  description = "Name of the SQL database"
  value       = var.create_sql_database ? module.sql_database[0].database_name : null
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<-EOT
  
  ==========================================
  QuickBuy Infrastructure Deployed Successfully!
  ==========================================
  
  Resource Group:       ${azurerm_resource_group.quickbuy.name}
  Location:             ${local.location}
  
  Storage Account:      ${module.storage.storage_account_name}
  Databricks Workspace: ${module.databricks.workspace_url}
  Event Hubs Namespace: ${module.eventhubs.namespace_name}
  Key Vault:            ${module.keyvault.key_vault_name}
  
  Next Steps:
  1. Access Databricks: ${module.databricks.workspace_url}
  2. Retrieve secrets from Key Vault: ${module.keyvault.key_vault_name}
  3. Configure Databricks clusters
  4. Deploy notebooks and workflows
  
  ==========================================
  EOT
}
