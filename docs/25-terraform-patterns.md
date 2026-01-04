# Terraform Patterns and Best Practices

Advanced Terraform patterns for managing infrastructure at scale.

## Table of Contents

1. [Module Design Patterns](#module-design-patterns)
2. [State Management](#state-management)
3. [Workspace Strategies](#workspace-strategies)
4. [Testing Infrastructure](#testing-infrastructure)
5. [CI/CD Integration](#cicd-integration)
6. [Security Practices](#security-practices)

---

## Module Design Patterns

### Module Structure

```
terraform/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── compute/
│   ├── database/
│   └── security/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── production/
└── global/
    ├── iam/
    └── dns/
```

### Root Module Pattern

```hcl
# environments/production/main.tf

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Use modules for consistent infrastructure
module "vpc" {
  source = "../../modules/networking"
  
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
  
  tags = local.common_tags
}

module "eks" {
  source = "../../modules/compute/eks"
  
  cluster_name    = "${var.project}-${var.environment}"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  
  node_groups = {
    general = {
      desired_size = 3
      min_size     = 2
      max_size     = 10
      instance_types = ["m5.large"]
    }
  }
  
  tags = local.common_tags
}
```

### Composable Modules

```hcl
# modules/compute/eks/main.tf

module "cluster" {
  source = "./cluster"
  
  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnets
}

module "node_groups" {
  source = "./node-groups"
  
  for_each = var.node_groups
  
  cluster_name    = module.cluster.name
  node_group_name = each.key
  config          = each.value
}

module "addons" {
  source = "./addons"
  
  cluster_name = module.cluster.name
  addons       = var.cluster_addons
  
  depends_on = [module.node_groups]
}
```

---

## State Management

### Remote State Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "project/environment/terraform.tfstate"
    region         = "us-east-1"
    
    # Encryption
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    
    # Locking
    dynamodb_table = "terraform-locks"
    
    # Assume role for access
    role_arn       = "arn:aws:iam::123456789:role/TerraformStateAccess"
  }
}
```

### State Data Source

```hcl
# Reference outputs from another state
data "terraform_remote_state" "networking" {
  backend = "s3"
  
  config = {
    bucket = "company-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use the outputs
resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.networking.outputs.private_subnet_id
}
```

### State File Structure

```
State Hierarchy:

Global State (IAM, DNS)
    │
    ├── Environment: Production
    │   ├── Networking
    │   ├── Data (RDS, ElastiCache)
    │   ├── Compute (EKS)
    │   └── Applications
    │
    ├── Environment: Staging
    │   └── ...
    │
    └── Environment: Development
        └── ...
```

---

## Workspace Strategies

### Environment Separation

**Option 1: Workspaces (Simple)**
```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod
terraform apply
```

```hcl
# Use workspace in configuration
locals {
  environment = terraform.workspace
  
  instance_sizes = {
    dev     = "t3.small"
    staging = "t3.medium"
    prod    = "m5.large"
  }
}

resource "aws_instance" "app" {
  instance_type = local.instance_sizes[local.environment]
}
```

**Option 2: Directory per Environment (Recommended for production)**
```
environments/
├── dev/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── staging/
│   └── ...
└── production/
    └── ...
```

---

## Testing Infrastructure

### Terratest Example

```go
// test/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpcModule(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/networking",
        Vars: map[string]interface{}{
            "vpc_cidr":     "10.0.0.0/16",
            "environment":  "test",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Assertions
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)

    privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    assert.Equal(t, 3, len(privateSubnets))
}
```

### Validation with terraform validate

```hcl
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  type = string
  
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}
```

---

## CI/CD Integration

### GitHub Actions Pipeline

```yaml
name: Terraform

on:
  pull_request:
    paths:
      - 'terraform/**'
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format
        run: terraform fmt -check -recursive
        
      - name: Terraform Init
        run: terraform init -backend=false
        
      - name: Terraform Validate
        run: terraform validate

  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Terraform Plan
        run: |
          terraform init
          terraform plan -out=tfplan
          
      - name: Upload Plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: tfplan

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          
      - name: Terraform Apply
        run: terraform apply tfplan
```

---

## Security Practices

### Sensitive Variables

```hcl
variable "database_password" {
  type      = string
  sensitive = true
  
  description = "Database master password"
}

# In terraform.tfvars (gitignored)
# database_password = "super-secret"

# Or via environment variable
# TF_VAR_database_password="super-secret"

# Or via secrets manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "production/database/password"
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### Policy as Code

```hcl
# Using Sentinel (Terraform Enterprise)
policy "require-tags" {
  source = "./policies/require-tags.sentinel"
  enforcement_level = "hard-mandatory"
}

# require-tags.sentinel
import "tfplan/v2" as tfplan

required_tags = ["environment", "project", "owner"]

all_resources = filter tfplan.resource_changes as _, rc {
    rc.mode == "managed" and
    rc.change.actions != ["delete"]
}

violations = filter all_resources as _, r {
    any required_tags as tag {
        r.change.after.tags[tag] is undefined
    }
}

main = rule {
    length(violations) == 0
}
```

### Resource Tagging

```hcl
locals {
  common_tags = {
    Environment  = var.environment
    Project      = var.project
    Owner        = var.owner
    ManagedBy    = "terraform"
    Repository   = "github.com/org/repo"
    CostCenter   = var.cost_center
  }
}

# Merge with resource-specific tags
resource "aws_instance" "app" {
  # ...
  
  tags = merge(local.common_tags, {
    Name = "app-server"
    Role = "application"
  })
}
```
