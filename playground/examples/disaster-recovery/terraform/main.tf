# Disaster Recovery Terraform Configuration

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "dr-terraform-state"
    key            = "disaster-recovery/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

variable "environment" {
  default = "production"
}

variable "primary_region" {
  default = "us-east-1"
}

variable "secondary_region" {
  default = "us-west-2"
}

# Primary Region Provider
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# Secondary Region Provider
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "disaster-recovery"
    ManagedBy   = "terraform"
  }
}

# ==============================================================================
# PRIMARY REGION VPC
# ==============================================================================

module "vpc_primary" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  providers = {
    aws = aws.primary
  }

  name = "dr-primary-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_vpn_gateway = true

  tags = local.common_tags
}

# ==============================================================================
# SECONDARY REGION VPC
# ==============================================================================

module "vpc_secondary" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  providers = {
    aws = aws.secondary
  }

  name = "dr-secondary-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = local.common_tags
}

# ==============================================================================
# VPC PEERING
# ==============================================================================

resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider = aws.primary
  
  vpc_id      = module.vpc_primary.vpc_id
  peer_vpc_id = module.vpc_secondary.vpc_id
  peer_region = var.secondary_region
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "primary-to-secondary-peering"
  })
}

resource "aws_vpc_peering_connection_accepter" "secondary" {
  provider = aws.secondary
  
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "secondary-accepts-primary-peering"
  })
}

# ==============================================================================
# RDS - PRIMARY DATABASE
# ==============================================================================

resource "aws_db_subnet_group" "primary" {
  provider = aws.primary
  
  name       = "dr-primary-db-subnet"
  subnet_ids = module.vpc_primary.private_subnets

  tags = local.common_tags
}

resource "aws_rds_cluster" "primary" {
  provider = aws.primary
  
  cluster_identifier      = "dr-primary-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  database_name           = "production"
  master_username         = "admin"
  master_password         = var.db_password
  
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [aws_security_group.db_primary.id]
  
  backup_retention_period = 35
  preferred_backup_window = "02:00-03:00"
  
  # Enable Global Database
  global_cluster_identifier = aws_rds_global_cluster.main.id
  
  deletion_protection = true
  skip_final_snapshot = false
  
  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "primary" {
  provider = aws.primary
  count    = 2
  
  identifier         = "dr-primary-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version

  tags = local.common_tags
}

# ==============================================================================
# RDS - GLOBAL DATABASE
# ==============================================================================

resource "aws_rds_global_cluster" "main" {
  provider = aws.primary
  
  global_cluster_identifier = "dr-global-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  database_name             = "production"
  
  deletion_protection = true
}

# ==============================================================================
# RDS - SECONDARY REPLICA
# ==============================================================================

resource "aws_db_subnet_group" "secondary" {
  provider = aws.secondary
  
  name       = "dr-secondary-db-subnet"
  subnet_ids = module.vpc_secondary.private_subnets

  tags = local.common_tags
}

resource "aws_rds_cluster" "secondary" {
  provider = aws.secondary
  
  cluster_identifier        = "dr-secondary-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "15.4"
  
  global_cluster_identifier = aws_rds_global_cluster.main.id
  
  db_subnet_group_name    = aws_db_subnet_group.secondary.name
  vpc_security_group_ids  = [aws_security_group.db_secondary.id]
  
  # Secondary cluster config
  enable_global_write_forwarding = true
  
  depends_on = [aws_rds_cluster_instance.primary]

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "secondary" {
  provider = aws.secondary
  count    = 2
  
  identifier         = "dr-secondary-${count.index}"
  cluster_identifier = aws_rds_cluster.secondary.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.secondary.engine
  engine_version     = aws_rds_cluster.secondary.engine_version

  tags = local.common_tags
}

# ==============================================================================
# S3 - CROSS REGION REPLICATION
# ==============================================================================

resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "dr-primary-data-${var.environment}"
  
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "dr-secondary-data-${var.environment}"
  
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "primary_to_secondary" {
  provider = aws.primary
  
  depends_on = [aws_s3_bucket_versioning.primary]
  
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }
  }
}

# ==============================================================================
# ROUTE 53 - DNS FAILOVER
# ==============================================================================

resource "aws_route53_health_check" "primary" {
  provider = aws.primary
  
  fqdn              = "api-primary.example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "10"

  tags = merge(local.common_tags, {
    Name = "primary-health-check"
  })
}

resource "aws_route53_health_check" "secondary" {
  provider = aws.primary
  
  fqdn              = "api-secondary.example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "10"

  tags = merge(local.common_tags, {
    Name = "secondary-health-check"
  })
}

resource "aws_route53_record" "api_primary" {
  provider = aws.primary
  
  zone_id = var.route53_zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "api_secondary" {
  provider = aws.primary
  
  zone_id = var.route53_zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.secondary.id
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "primary_vpc_id" {
  value = module.vpc_primary.vpc_id
}

output "secondary_vpc_id" {
  value = module.vpc_secondary.vpc_id
}

output "global_cluster_arn" {
  value = aws_rds_global_cluster.main.arn
}

output "primary_db_endpoint" {
  value = aws_rds_cluster.primary.endpoint
}

output "secondary_db_endpoint" {
  value = aws_rds_cluster.secondary.endpoint
}

variable "db_password" {
  sensitive = true
}

variable "route53_zone_id" {
  default = ""
}

# Placeholder for LBs
resource "aws_lb" "primary" {
  provider = aws.primary
  name     = "dr-primary-alb"
  internal = false
  load_balancer_type = "application"
  subnets  = module.vpc_primary.public_subnets
  
  tags = local.common_tags
}

resource "aws_lb" "secondary" {
  provider = aws.secondary
  name     = "dr-secondary-alb"
  internal = false
  load_balancer_type = "application"
  subnets  = module.vpc_secondary.public_subnets
  
  tags = local.common_tags
}

# Security Groups (placeholder)
resource "aws_security_group" "db_primary" {
  provider = aws.primary
  vpc_id   = module.vpc_primary.vpc_id
  name     = "dr-primary-db-sg"
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc_primary.vpc_cidr_block, module.vpc_secondary.vpc_cidr_block]
  }
  
  tags = local.common_tags
}

resource "aws_security_group" "db_secondary" {
  provider = aws.secondary
  vpc_id   = module.vpc_secondary.vpc_id
  name     = "dr-secondary-db-sg"
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc_primary.vpc_cidr_block, module.vpc_secondary.vpc_cidr_block]
  }
  
  tags = local.common_tags
}

# IAM Role for S3 Replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "s3-crr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}
