# Banking System Infrastructure - Azure

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.app_name}-${var.environment}-rg"
  location = var.location
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.app_name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.app_name

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 20
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

  tags = local.common_tags
}

# Azure PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.app_name}-pg"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = "bankadmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = var.db_sku

  backup_retention_days = 35

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "banking"
  server_id = azurerm_postgresql_flexible_server.main.id
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  name                = "${var.app_name}-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = local.common_tags
}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                = "${var.app_name}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = true

  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.app_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "Node.JS"

  tags = local.common_tags
}

data "azurerm_client_config" "current" {}

# Variables
variable "app_name" {
  default = "banking"
}

variable "environment" {
  default = "production"
}

variable "location" {
  default = "East US"
}

variable "node_count" {
  default = 3
}

variable "vm_size" {
  default = "Standard_D2_v2"
}

variable "db_sku" {
  default = "GP_Standard_D2s_v3"
}

variable "db_password" {
  sensitive = true
}

locals {
  common_tags = {
    Application = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Outputs
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "redis_hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}
