# Multi-Cloud Infrastructure - Main Terraform Configuration

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket         = "multi-cloud-tfstate"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# ==============================================================================
# VARIABLES
# ==============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "primary_cloud" {
  description = "Primary cloud provider"
  type        = string
  default     = "aws"
  
  validation {
    condition     = contains(["aws", "gcp", "azure"], var.primary_cloud)
    error_message = "Primary cloud must be aws, gcp, or azure."
  }
}

variable "enable_dr" {
  description = "Enable disaster recovery configuration"
  type        = bool
  default     = true
}

variable "cluster_config" {
  description = "Kubernetes cluster configuration"
  type = object({
    node_count     = number
    node_size      = string
    k8s_version    = string
    enable_autopilot = bool
  })
  default = {
    node_count     = 3
    node_size      = "medium"
    k8s_version    = "1.28"
    enable_autopilot = false
  }
}

variable "regions" {
  description = "Regions per cloud provider"
  type = map(object({
    primary   = string
    secondary = string
  }))
  default = {
    aws = {
      primary   = "us-east-1"
      secondary = "us-west-2"
    }
    gcp = {
      primary   = "us-central1"
      secondary = "us-east4"
    }
    azure = {
      primary   = "eastus"
      secondary = "westus2"
    }
  }
}

variable "cost_tags" {
  description = "Cost allocation tags"
  type        = map(string)
  default = {
    project     = "multi-cloud-platform"
    team        = "platform-engineering"
    cost-center = "infrastructure"
  }
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  common_tags = merge(var.cost_tags, {
    environment = var.environment
    managed-by  = "terraform"
    project     = "multi-cloud-infrastructure"
  })

  node_sizes = {
    small  = { aws = "t3.medium", gcp = "e2-medium", azure = "Standard_D2s_v3" }
    medium = { aws = "t3.large", gcp = "e2-standard-4", azure = "Standard_D4s_v3" }
    large  = { aws = "t3.xlarge", gcp = "e2-standard-8", azure = "Standard_D8s_v3" }
  }

  cluster_name = "multicloud-${var.environment}"
}

# ==============================================================================
# AWS PROVIDER & RESOURCES
# ==============================================================================

provider "aws" {
  region = var.regions.aws.primary
  
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.regions.aws.secondary
  
  default_tags {
    tags = local.common_tags
  }
}

# VPC Module
module "aws_vpc" {
  source = "./modules/aws/vpc"
  count  = var.primary_cloud == "aws" ? 1 : 0

  name        = "${local.cluster_name}-vpc"
  cidr_block  = "10.0.0.0/16"
  environment = var.environment
  
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"
}

# EKS Cluster
module "aws_eks" {
  source = "./modules/aws/eks"
  count  = var.primary_cloud == "aws" ? 1 : 0

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_config.k8s_version
  
  vpc_id          = module.aws_vpc[0].vpc_id
  subnet_ids      = module.aws_vpc[0].private_subnets
  
  node_groups = {
    general = {
      desired_size = var.cluster_config.node_count
      min_size     = 1
      max_size     = var.cluster_config.node_count * 2
      
      instance_types = [local.node_sizes[var.cluster_config.node_size].aws]
      capacity_type  = var.environment == "production" ? "ON_DEMAND" : "SPOT"
      
      labels = {
        role = "general"
      }
    }
  }
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
  
  enable_cluster_autoscaler = true
}

# Aurora PostgreSQL (AWS)
module "aws_aurora" {
  source = "./modules/aws/aurora"
  count  = var.primary_cloud == "aws" ? 1 : 0

  cluster_identifier = "${local.cluster_name}-db"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  
  master_username = "admin"
  database_name   = "multicloud"
  
  vpc_id              = module.aws_vpc[0].vpc_id
  subnet_ids          = module.aws_vpc[0].private_subnets
  allowed_cidr_blocks = [module.aws_vpc[0].vpc_cidr_block]
  
  instance_class = var.environment == "production" ? "db.r6g.large" : "db.t4g.medium"
  instance_count = var.environment == "production" ? 2 : 1
  
  backup_retention_period = var.environment == "production" ? 30 : 7
  enable_global_cluster   = var.enable_dr
}

# ==============================================================================
# GCP PROVIDER & RESOURCES
# ==============================================================================

provider "google" {
  project = var.gcp_project_id
  region  = var.regions.gcp.primary
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "multi-cloud-project"
}

# GCP VPC
module "gcp_vpc" {
  source = "./modules/gcp/vpc"
  count  = var.primary_cloud == "gcp" || var.enable_dr ? 1 : 0

  project_id  = var.gcp_project_id
  name        = "${local.cluster_name}-vpc"
  environment = var.environment
  
  region = var.regions.gcp.primary
  
  subnets = [
    {
      name          = "gke-subnet"
      ip_cidr_range = "10.1.0.0/20"
      region        = var.regions.gcp.primary
      secondary_ranges = [
        { range_name = "pods", ip_cidr_range = "10.4.0.0/14" },
        { range_name = "services", ip_cidr_range = "10.8.0.0/20" }
      ]
    }
  ]
}

# GKE Cluster
module "gcp_gke" {
  source = "./modules/gcp/gke"
  count  = var.primary_cloud == "gcp" || var.enable_dr ? 1 : 0

  project_id     = var.gcp_project_id
  cluster_name   = local.cluster_name
  region         = var.regions.gcp.primary
  
  network    = module.gcp_vpc[0].network_name
  subnetwork = module.gcp_vpc[0].subnets["gke-subnet"].name
  
  pods_range_name     = "pods"
  services_range_name = "services"
  
  enable_autopilot = var.cluster_config.enable_autopilot
  
  node_pools = var.cluster_config.enable_autopilot ? [] : [
    {
      name           = "general"
      machine_type   = local.node_sizes[var.cluster_config.node_size].gcp
      node_count     = var.cluster_config.node_count
      min_count      = 1
      max_count      = var.cluster_config.node_count * 2
      disk_size_gb   = 100
      preemptible    = var.environment != "production"
      auto_upgrade   = true
      auto_repair    = true
    }
  ]
  
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal"
    }
  ]
}

# Cloud SQL (GCP)
module "gcp_cloudsql" {
  source = "./modules/gcp/cloudsql"
  count  = var.primary_cloud == "gcp" || var.enable_dr ? 1 : 0

  project_id = var.gcp_project_id
  name       = "${local.cluster_name}-db"
  region     = var.regions.gcp.primary
  
  database_version = "POSTGRES_15"
  tier             = var.environment == "production" ? "db-custom-4-16384" : "db-f1-micro"
  
  network_id = module.gcp_vpc[0].network_id
  
  high_availability = var.environment == "production"
  backup_enabled    = true
  
  databases = ["multicloud"]
  
  labels = local.common_tags
}

# ==============================================================================
# AZURE PROVIDER & RESOURCES
# ==============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  count    = var.primary_cloud == "azure" || var.enable_dr ? 1 : 0
  name     = "rg-${local.cluster_name}"
  location = var.regions.azure.primary
  
  tags = local.common_tags
}

# Azure VNet
module "azure_vnet" {
  source = "./modules/azure/vnet"
  count  = var.primary_cloud == "azure" || var.enable_dr ? 1 : 0

  resource_group_name = azurerm_resource_group.main[0].name
  location            = azurerm_resource_group.main[0].location
  
  name          = "${local.cluster_name}-vnet"
  address_space = ["10.2.0.0/16"]
  
  subnets = [
    {
      name             = "aks-subnet"
      address_prefixes = ["10.2.0.0/20"]
    },
    {
      name             = "db-subnet"
      address_prefixes = ["10.2.16.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  ]
  
  tags = local.common_tags
}

# AKS Cluster
module "azure_aks" {
  source = "./modules/azure/aks"
  count  = var.primary_cloud == "azure" || var.enable_dr ? 1 : 0

  resource_group_name = azurerm_resource_group.main[0].name
  location            = azurerm_resource_group.main[0].location
  
  cluster_name = local.cluster_name
  dns_prefix   = local.cluster_name
  
  kubernetes_version = var.cluster_config.k8s_version
  
  vnet_subnet_id = module.azure_vnet[0].subnets["aks-subnet"].id
  
  default_node_pool = {
    name                = "general"
    node_count          = var.cluster_config.node_count
    vm_size             = local.node_sizes[var.cluster_config.node_size].azure
    enable_auto_scaling = true
    min_count           = 1
    max_count           = var.cluster_config.node_count * 2
  }
  
  network_profile = {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }
  
  tags = local.common_tags
}

# Azure PostgreSQL
module "azure_postgresql" {
  source = "./modules/azure/postgresql"
  count  = var.primary_cloud == "azure" || var.enable_dr ? 1 : 0

  resource_group_name = azurerm_resource_group.main[0].name
  location            = azurerm_resource_group.main[0].location
  
  server_name         = "${local.cluster_name}-db"
  sku_name            = var.environment == "production" ? "GP_Gen5_4" : "B_Gen5_1"
  storage_mb          = var.environment == "production" ? 102400 : 32768
  
  administrator_login          = "pgadmin"
  administrator_login_password = random_password.db_password.result
  
  postgresql_version     = "15"
  ssl_enforcement_enabled = true
  
  geo_redundant_backup_enabled = var.environment == "production"
  backup_retention_days        = var.environment == "production" ? 30 : 7
  
  subnet_id = module.azure_vnet[0].subnets["db-subnet"].id
  
  databases = ["multicloud"]
  
  tags = local.common_tags
}

resource "random_password" "db_password" {
  length  = 24
  special = true
}

# ==============================================================================
# CROSS-CLOUD SERVICES
# ==============================================================================

# Vault for secrets management
module "vault" {
  source = "./modules/common/vault"

  environment       = var.environment
  primary_cloud     = var.primary_cloud
  
  aws_kms_key_id    = var.primary_cloud == "aws" ? module.aws_kms[0].key_id : null
  gcp_kms_key_name  = var.primary_cloud == "gcp" ? module.gcp_kms[0].key_name : null
  azure_key_vault   = var.primary_cloud == "azure" ? module.azure_keyvault[0].vault_uri : null
  
  replicas = var.environment == "production" ? 3 : 1
}

# Consul for service mesh
module "consul" {
  source = "./modules/common/consul"

  environment = var.environment
  
  aws_eks_cluster   = var.primary_cloud == "aws" ? module.aws_eks[0].cluster_endpoint : null
  gcp_gke_cluster   = var.primary_cloud == "gcp" || var.enable_dr ? module.gcp_gke[0].cluster_endpoint : null
  azure_aks_cluster = var.primary_cloud == "azure" || var.enable_dr ? module.azure_aks[0].cluster_fqdn : null
  
  enable_federation = var.enable_dr
  replicas          = var.environment == "production" ? 5 : 3
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "clusters" {
  description = "Kubernetes cluster endpoints"
  value = {
    aws   = var.primary_cloud == "aws" ? module.aws_eks[0].cluster_endpoint : null
    gcp   = var.primary_cloud == "gcp" || var.enable_dr ? module.gcp_gke[0].cluster_endpoint : null
    azure = var.primary_cloud == "azure" || var.enable_dr ? module.azure_aks[0].cluster_fqdn : null
  }
}

output "databases" {
  description = "Database connection strings"
  sensitive   = true
  value = {
    aws   = var.primary_cloud == "aws" ? module.aws_aurora[0].connection_string : null
    gcp   = var.primary_cloud == "gcp" || var.enable_dr ? module.gcp_cloudsql[0].connection_string : null
    azure = var.primary_cloud == "azure" || var.enable_dr ? module.azure_postgresql[0].connection_string : null
  }
}

output "vault_endpoint" {
  description = "Vault endpoint"
  value       = module.vault.endpoint
}

output "consul_endpoint" {
  description = "Consul endpoint"
  value       = module.consul.endpoint
}
