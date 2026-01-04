# Food Delivery Infrastructure - GCP

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.app_name}-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.app_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      app = var.app_name
    }
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 10
  }
}

# Cloud SQL PostgreSQL
resource "google_sql_database_instance" "main" {
  name             = "${var.app_name}-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.db_tier

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      private_network = google_compute_network.vpc.id
    }

    location_preference {
      zone = "${var.region}-a"
    }
  }
}

resource "google_sql_database" "database" {
  name     = "food_delivery"
  instance = google_sql_database_instance.main.name
}

# Redis (Memorystore)
resource "google_redis_instance" "cache" {
  name           = "${var.app_name}-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region

  authorized_network = google_compute_network.vpc.id
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.app_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.app_name}-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Cloud Storage for images
resource "google_storage_bucket" "media" {
  name     = "${var.project_id}-${var.app_name}-media"
  location = var.region

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  default = "us-central1"
}

variable "app_name" {
  default = "food-delivery"
}

variable "node_count" {
  default = 3
}

variable "machine_type" {
  default = "e2-medium"
}

variable "db_tier" {
  default = "db-f1-micro"
}

# Outputs
output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "db_connection" {
  value     = google_sql_database_instance.main.connection_name
  sensitive = true
}

output "redis_host" {
  value = google_redis_instance.cache.host
}
