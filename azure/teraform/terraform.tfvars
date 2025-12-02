# ============================================
# QuickBuy Terraform Variables
# File: terraform.tfvars
# ============================================
# IMPORTANT: Do not commit this file to Git if it contains sensitive data
# Add terraform.tfvars to .gitignore
# ============================================

# Project Configuration
project_name   = "quickbuy"
environment    = "dev"
location       = "centralindia"
location_short = "cin"

# GitHub Configuration
github_username = "yourusername"  # Replace with your actual GitHub username

# Tags
tags = {
  Owner              = "DataEngineering"
  CostCenter         = "Analytics"
  Criticality        = "Medium"
  DataClassification = "Internal"
  Department         = "Engineering"
}

# Event Hubs Configuration
eventhubs_sku      = "Standard"
eventhubs_capacity = 1  # Start with 1 throughput unit, scale up as needed

# SQL Database Configuration
create_sql_database = false  # Set to true if you want SQL Database
sql_admin_username  = "quickbuyadmin"
sql_admin_password  = ""  # Set a strong password or use environment variable
sql_database_sku    = "Basic"

# Monitoring Configuration
log_retention_days = 30

# Cost Management
enable_cost_alerts    = true
monthly_budget_amount = 20000  # INR
