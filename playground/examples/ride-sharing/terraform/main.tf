# Ride Sharing Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "${var.app_name}-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    main = {
      min_size     = 5
      max_size     = 100
      desired_size = 10
      instance_types = ["m5.large"]
    }
  }
}

# RDS with PostGIS
resource "aws_db_instance" "main" {
  identifier           = "${var.app_name}-db"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.r5.large"
  allocated_storage    = 100
  max_allocated_storage = 500

  db_name  = "rideshare"
  username = "admin"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 30
  multi_az               = true

  # PostGIS extension is enabled via parameter group
  parameter_group_name = aws_db_parameter_group.postgis.name
}

resource "aws_db_parameter_group" "postgis" {
  name   = "${var.app_name}-postgis"
  family = "postgres15"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
}

# ElastiCache Redis Cluster (for real-time location)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.app_name}-redis"
  description                = "Redis cluster for real-time data"
  node_type                  = "cache.r5.large"
  num_cache_clusters         = 3
  automatic_failover_enabled = true
  port                       = 6379
}

# SNS for notifications
resource "aws_sns_topic" "ride_notifications" {
  name = "${var.app_name}-notifications"
}

# SQS for ride matching queue
resource "aws_sqs_queue" "ride_requests" {
  name                      = "${var.app_name}-ride-requests"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}

# Variables
variable "app_name" {
  default = "ride-sharing"
}

variable "region" {
  default = "us-east-1"
}

variable "db_password" {
  sensitive = true
}

# Security Groups
resource "aws_security_group" "rds" {
  name   = "${var.app_name}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet"
  subnet_ids = module.vpc.private_subnets
}
