# IoT Platform Infrastructure - AWS

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

# IoT Core
resource "aws_iot_thing" "devices" {
  count = var.device_count
  name  = "${var.app_name}-device-${count.index}"
}

resource "aws_iot_policy" "device_policy" {
  name = "${var.app_name}-device-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect", "iot:Publish", "iot:Subscribe", "iot:Receive"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iot_topic_rule" "telemetry" {
  name        = "${var.app_name}_telemetry_rule"
  sql         = "SELECT * FROM 'devices/+/telemetry'"
  sql_version = "2016-03-23"
  enabled     = true

  timestream {
    database_name = aws_timestreamwrite_database.main.database_name
    table_name    = aws_timestreamwrite_table.telemetry.table_name
    role_arn      = aws_iam_role.iot_timestream.arn
    
    dimension {
      name  = "device_id"
      value = "$${topic(2)}"
    }
  }
}

# Timestream for time-series data
resource "aws_timestreamwrite_database" "main" {
  database_name = "${var.app_name}-db"
}

resource "aws_timestreamwrite_table" "telemetry" {
  database_name = aws_timestreamwrite_database.main.database_name
  table_name    = "telemetry"

  retention_properties {
    magnetic_store_retention_period_in_days = 365
    memory_store_retention_period_in_hours  = 24
  }
}

# Lambda for processing
resource "aws_lambda_function" "processor" {
  function_name = "${var.app_name}-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.alerts.name
    }
  }
}

# DynamoDB for alerts
resource "aws_dynamodb_table" "alerts" {
  name         = "${var.app_name}-alerts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.app_name}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
}

# IAM Roles
resource "aws_iam_role" "iot_timestream" {
  name = "${var.app_name}-iot-timestream-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Variables
variable "app_name" {
  default = "iot-platform"
}

variable "region" {
  default = "us-east-1"
}

variable "device_count" {
  default = 3
}

# Outputs
output "iot_endpoint" {
  value = data.aws_iot_endpoint.current.endpoint_address
}

output "timestream_database" {
  value = aws_timestreamwrite_database.main.database_name
}

data "aws_iot_endpoint" "current" {
  endpoint_type = "iot:Data-ATS"
}
