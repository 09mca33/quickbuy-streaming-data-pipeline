# ============================================
# QuickBuy Terraform Variables
# ============================================

# ============================================
# Project Information
# ============================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "quickbuy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia"
}

variable "location_short" {
  description = "Short form of Azure region"
  type        = string
  default     = "cin"
}

variable "github_username" {
  description = "GitHub username for repository link"
  type        = string
  default     = "yourusername"
}

# ============================================
# Tags
# ============================================

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner            = "DataEngineering"
    CostCenter       = "Analytics"
    Criticality      = "Medium"
    DataClassification = "Internal"
  }
}

# ============================================
# Event Hubs Configuration
# ============================================

variable "eventhubs_sku" {
  description = "SKU for Event Hubs namespace (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.eventhubs_sku)
    error_message = "Event Hubs SKU must be Basic, Standard, or Premium."
  }
}

variable "eventhubs_capacity" {
  description = "Throughput units for Event Hubs (1-20 for Standard)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.eventhubs_capacity >= 1 && var.eventhubs_capacity <= 20
    error_message = "Event Hubs capacity must be between 1 and 20."
  }
}

# ============================================
# SQL Database Configuration
# ============================================

variable "create_sql_database" {
  description = "Whether to create SQL Database (set to false to save costs)"
  type        = bool
  default     = false
}

variable "sql_admin_username" {
  description = "Admin username for SQL Server"
  type        = string
  default     = "quickbuyadmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Admin password for SQL Server (must be complex)"
  type        = string
  default     = ""
  sensitive   = true
  
  validation {
    condition     = var.sql_admin_password == "" || length(var.sql_admin_password) >= 8
    error_message = "SQL admin password must be at least 8 characters long."
  }
}

variable "sql_database_sku" {
  description = "SKU for SQL Database (Basic, S0, S1, etc.)"
  type        = string
  default     = "Basic"
}

# ============================================
# Monitoring Configuration
# ============================================

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

# ============================================
# Cost Management
# ============================================

variable "enable_cost_alerts" {
  description = "Enable cost alerts for budget management"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget in INR (for cost alerts)"
  type        = number
  default     = 20000
}
