# LMS Platform Infrastructure

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

# S3 for video/content storage
resource "aws_s3_bucket" "content" {
  bucket = "${var.app_name}-content-${var.environment}"
}

resource "aws_s3_bucket_cors_configuration" "content" {
  bucket = aws_s3_bucket.content.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# CloudFront CDN
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.content.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.content.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

# RDS PostgreSQL
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier     = "${var.app_name}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class

  allocated_storage = 20
  db_name           = "lms"
  username          = "lms_admin"
  port              = 5432

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = var.subnet_ids

  backup_retention_period = 7
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.app_name}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
}

# Security Group
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

# Variables
variable "app_name" {
  default = "lms-platform"
}

variable "environment" {
  default = "production"
}

variable "region" {
  default = "us-east-1"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_ids" {
  type = list(string)
}

# Outputs
output "cdn_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "content_bucket" {
  value = aws_s3_bucket.content.bucket
}

output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}
