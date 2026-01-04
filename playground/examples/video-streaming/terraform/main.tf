# Video Streaming Infrastructure

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

# S3 for video storage
resource "aws_s3_bucket" "videos" {
  bucket = "${var.app_name}-videos-${var.environment}"
}

resource "aws_s3_bucket" "transcoded" {
  bucket = "${var.app_name}-transcoded-${var.environment}"
}

# CloudFront CDN
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.transcoded.bucket_regional_domain_name
    origin_id   = "S3-transcoded"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-transcoded"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name}"
}

# MediaConvert for transcoding
resource "aws_media_convert_queue" "main" {
  name   = "${var.app_name}-transcode-queue"
  status = "ACTIVE"
}

# Lambda for processing uploads
resource "aws_lambda_function" "transcoder_trigger" {
  function_name = "${var.app_name}-transcode-trigger"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda.zip"

  environment {
    variables = {
      MEDIACONVERT_QUEUE = aws_media_convert_queue.main.arn
      OUTPUT_BUCKET      = aws_s3_bucket.transcoded.bucket
    }
  }
}

# S3 trigger
resource "aws_s3_bucket_notification" "upload" {
  bucket = aws_s3_bucket.videos.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transcoder_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}

# RDS
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier     = "${var.app_name}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.medium"

  allocated_storage = 50
  db_name           = "video"
  username          = "admin"
}

# IAM
resource "aws_iam_role" "lambda" {
  name = "${var.app_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Variables
variable "app_name" { default = "video-streaming" }
variable "environment" { default = "production" }
variable "region" { default = "us-east-1" }

# Outputs
output "cdn_domain" { value = aws_cloudfront_distribution.cdn.domain_name }
output "upload_bucket" { value = aws_s3_bucket.videos.bucket }
