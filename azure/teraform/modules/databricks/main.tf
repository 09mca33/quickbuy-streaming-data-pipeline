# ============================================
# Databricks Module
# Path: modules/databricks/main.tf
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
# Databricks Workspace
# ============================================

resource "azurerm_databricks_workspace" "quickbuy" {
  name                = "dbw-${var.project_name}-${var.environment}-${var.location_short}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  
  tags = var.tags
}

# ============================================
# Managed Resource Group (created by Databricks)
# ============================================

# This resource group is automatically created by Azure Databricks
# We're just referencing it here for documentation

# ============================================
# Grant Databricks Access to Storage Account
# ============================================

# Get the Databricks workspace identity
data "azurerm_databricks_workspace" "quickbuy" {
  name                = azurerm_databricks_workspace.quickbuy.name
  resource_group_name = var.resource_group_name
  
  depends_on = [azurerm_databricks_workspace.quickbuy]
}

# Grant Storage Blob Data Contributor role to Databricks
resource "azurerm_role_assignment" "databricks_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_workspace.quickbuy.storage_account_identity[0].principal_id
  
  depends_on = [azurerm_databricks_workspace.quickbuy]
}

# ============================================
# Outputs
# ============================================

output "workspace_id" {
  description = "ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.quickbuy.id
}

output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = "https://${azurerm_databricks_workspace.quickbuy.workspace_url}"
}

output "workspace_name" {
  description = "Name of the Databricks workspace"
  value       = azurerm_databricks_workspace.quickbuy.name
}

# ============================================
# Variables for this module
# Path: modules/databricks/variables.tf
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

variable "sku" {
  description = "SKU for Databricks workspace (standard or premium)"
  type        = string
  default     = "premium"
  
  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "storage_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the storage account"
  type        = string
}# ============================================
# Databricks Module
# Path: modules/databricks/main.tf
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
# Databricks Workspace
# ============================================

resource "azurerm_databricks_workspace" "quickbuy" {
  name                = "dbw-${var.project_name}-${var.environment}-${var.location_short}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  
  tags = var.tags
}

# ============================================
# Managed Resource Group (created by Databricks)
# ============================================

# This resource group is automatically created by Azure Databricks
# We're just referencing it here for documentation

# ============================================
# Grant Databricks Access to Storage Account
# ============================================

# Get the Databricks workspace identity
data "azurerm_databricks_workspace" "quickbuy" {
  name                = azurerm_databricks_workspace.quickbuy.name
  resource_group_name = var.resource_group_name
  
  depends_on = [azurerm_databricks_workspace.quickbuy]
}

# Grant Storage Blob Data Contributor role to Databricks
resource "azurerm_role_assignment" "databricks_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_workspace.quickbuy.storage_account_identity[0].principal_id
  
  depends_on = [azurerm_databricks_workspace.quickbuy]
}

# ============================================
# Outputs
# ============================================

output "workspace_id" {
  description = "ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.quickbuy.id
}

output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = "https://${azurerm_databricks_workspace.quickbuy.workspace_url}"
}

output "workspace_name" {
  description = "Name of the Databricks workspace"
  value       = azurerm_databricks_workspace.quickbuy.name
}

# ============================================
# Variables for this module
# Path: modules/databricks/variables.tf
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

variable "sku" {
  description = "SKU for Databricks workspace (standard or premium)"
  type        = string
  default     = "premium"
  
  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "storage_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the storage account"
  type        = string
}
