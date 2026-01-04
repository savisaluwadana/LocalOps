# Azure AKS Module

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS"
  type        = string
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  })
}

variable "network_profile" {
  description = "Network profile configuration"
  type = object({
    network_plugin    = string
    load_balancer_sku = string
    network_policy    = string
  })
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = var.default_node_pool.name
    node_count          = var.default_node_pool.node_count
    vm_size             = var.default_node_pool.vm_size
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    min_count           = var.default_node_pool.min_count
    max_count           = var.default_node_pool.max_count
    vnet_subnet_id      = var.vnet_subnet_id
    
    upgrade_settings {
      max_surge = "10%"
    }

    # Enable encryption at host
    enable_host_encryption = true
    
    # Node labels
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "production"
    }

    # Availability zones
    zones = ["1", "2", "3"]
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network profile
  network_profile {
    network_plugin     = var.network_profile.network_plugin
    load_balancer_sku  = var.network_profile.load_balancer_sku
    network_policy     = var.network_profile.network_policy
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
  }

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
  }

  # Key vault secrets provider
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Enable OIDC issuer for Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  # Microsoft Defender
  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [2, 3, 4, 5]
    }
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4, 5]
    }
  }

  # Automatic channel upgrade
  automatic_channel_upgrade = "stable"

  # SKU tier
  sku_tier = "Standard"

  # Storage profile
  storage_profile {
    blob_driver_enabled = true
    file_driver_enabled = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Additional Node Pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D4s_v3"
  
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 10
  
  vnet_subnet_id = var.vnet_subnet_id
  
  zones = ["1", "2", "3"]
  
  node_labels = {
    "nodepool-type" = "workload"
    "workload-type" = "general"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# GPU Node Pool (optional)
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count                 = 0 # Set to 1 to enable
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_NC6s_v3"
  
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = 4
  
  vnet_subnet_id = var.vnet_subnet_id
  
  node_taints = [
    "nvidia.com/gpu=true:NoSchedule"
  ]
  
  node_labels = {
    "nodepool-type" = "gpu"
    "gpu-type"      = "nvidia"
  }

  tags = var.tags
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Outputs
output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive = true
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity
}
