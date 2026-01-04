# Healthcare Infrastructure - HIPAA Compliant

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

# VPC with private subnets only
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  
  # Enable VPC Flow Logs for HIPAA compliance
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
}

# EKS with encryption
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "${var.app_name}-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }
}

# KMS for encryption
resource "aws_kms_key" "eks" {
  description             = "EKS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# RDS with encryption
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier     = "${var.app_name}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.r5.large"

  allocated_storage = 100
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = "healthcare"
  username = "admin"

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.private_subnets

  backup_retention_period = 35
  deletion_protection     = true
  multi_az               = true
}

# S3 with encryption for PHI
resource "aws_s3_bucket" "phi_storage" {
  bucket = "${var.app_name}-phi-${var.environment}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "phi" {
  bucket = aws_s3_bucket.phi_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "phi" {
  bucket = aws_s3_bucket.phi_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "s3" {
  description             = "S3 PHI encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "main" {
  name           = "${var.app_name}-trail"
  s3_bucket_name = aws_s3_bucket.logs.id
  
  enable_log_file_validation = true
  is_multi_region_trail      = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-audit-logs-${var.environment}"
}

# Security Group
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

# Variables
variable "app_name" { default = "healthcare" }
variable "environment" { default = "production" }
variable "region" { default = "us-east-1" }
