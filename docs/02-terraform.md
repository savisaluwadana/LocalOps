# Terraform and Infrastructure as Code Complete Guide

## Table of Contents

1. [Infrastructure as Code Fundamentals](#infrastructure-as-code-fundamentals)
2. [What is Terraform?](#what-is-terraform)
3. [Core Concepts](#core-concepts)
4. [HCL Language](#hcl-language)
5. [State Management](#state-management)
6. [Modules](#modules)
7. [Workspaces and Environments](#workspaces-and-environments)
8. [Best Practices](#best-practices)
9. [Testing Infrastructure](#testing-infrastructure)
10. [Enterprise Patterns](#enterprise-patterns)

---

## Infrastructure as Code Fundamentals

### What is Infrastructure as Code (IaC)?

IaC is the practice of managing infrastructure through code instead of manual processes. Everything—servers, networks, databases, load balancers—is defined in configuration files.

### The Before and After

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TRADITIONAL vs IaC                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   TRADITIONAL (Manual/ClickOps)                                                     │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  1. Log into AWS Console                                                     │   │
│   │  2. Click "Create VPC"                                                       │   │
│   │  3. Click "Create Subnet"                                                    │   │
│   │  4. Click "Launch EC2 Instance"                                              │   │
│   │  5. Configure security group manually                                        │   │
│   │  6. Hope you remember all the settings                                       │   │
│   │  7. Try to recreate it the same way in staging                              │   │
│   │  8. Document it in a wiki (maybe, someday)                                   │   │
│   │  9. Differences accumulate between environments                              │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Problems:                                                                          │
│   • Not reproducible                                                                │
│   • No version history                                                              │
│   • Configuration drift                                                             │
│   • Human error                                                                     │
│   • Slow to scale                                                                   │
│                                                                                      │
│   INFRASTRUCTURE AS CODE                                                             │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  1. Write code describing desired infrastructure                             │   │
│   │  2. Store in version control (Git)                                           │   │
│   │  3. Review changes in pull request                                           │   │
│   │  4. Run `terraform apply`                                                    │   │
│   │  5. Same code → same infrastructure every time                               │   │
│   │  6. Easy to see what changed and when                                       │   │
│   │  7. Destroy and recreate environments in minutes                            │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   Benefits:                                                                          │
│   ✓ Reproducible                                                                    │
│   ✓ Version controlled                                                              │
│   ✓ Self-documenting                                                                │
│   ✓ Automated                                                                       │
│   ✓ Consistent across environments                                                 │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### IaC Benefits Explained

| Benefit | Description |
|---------|-------------|
| **Version Control** | Track every change to infrastructure, who made it, when, and why |
| **Reproducibility** | Create identical environments reliably |
| **Documentation** | The code IS the documentation |
| **Speed** | Spin up entire environments in minutes |
| **Cost Reduction** | Easily tear down unused resources |
| **Collaboration** | Teams can review infrastructure changes like code |
| **Compliance** | Enforce security policies systematically |

### Types of IaC Tools

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           IaC TOOL CATEGORIES                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   DECLARATIVE (What you want)                                                        │
│   ├── Terraform          "I want 3 EC2 instances"                                   │
│   ├── CloudFormation     (Tool figures out how to get there)                        │
│   ├── Pulumi                                                                         │
│   └── Crossplane                                                                     │
│                                                                                      │
│   IMPERATIVE (How to do it)                                                          │
│   ├── Bash scripts       "Create instance 1, create instance 2..."                  │
│   ├── Python boto3       (You specify every step)                                   │
│   └── Ansible (hybrid)                                                              │
│                                                                                      │
│   Declarative is preferred because:                                                  │
│   • You describe desired end state                                                  │
│   • Tool handles ordering, dependencies                                             │
│   • Idempotent (safe to run multiple times)                                         │
│   • Easier to understand                                                            │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## What is Terraform?

### Definition

**Terraform** is an open-source Infrastructure as Code tool created by HashiCorp. It lets you define both cloud and on-premise resources in human-readable configuration files.

### Why Terraform?

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           WHY TERRAFORM?                                             │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   MULTI-CLOUD                                                                        │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   Same language for:                                                         │   │
│   │                                                                              │   │
│   │   ┌───────┐   ┌───────┐   ┌───────┐   ┌───────┐   ┌───────┐               │   │
│   │   │  AWS  │   │  GCP  │   │ Azure │   │  K8s  │   │ 3000+ │               │   │
│   │   │       │   │       │   │       │   │       │   │others │               │   │
│   │   └───────┘   └───────┘   └───────┘   └───────┘   └───────┘               │   │
│   │                                                                              │   │
│   │   vs CloudFormation (AWS only) or ARM templates (Azure only)                │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   DECLARATIVE SYNTAX                                                                 │
│   • Describe WHAT you want, not HOW to do it                                        │
│   • Terraform figures out the order                                                 │
│   • Handles dependencies automatically                                              │
│                                                                                      │
│   STATE MANAGEMENT                                                                   │
│   • Tracks what exists vs what's defined                                            │
│   • Knows what to create, update, or delete                                         │
│   • Detects drift from desired state                                                │
│                                                                                      │
│   LARGE ECOSYSTEM                                                                    │
│   • 3000+ providers                                                                 │
│   • Thousands of community modules                                                  │
│   • Active open-source community                                                    │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### How Terraform Works

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TERRAFORM WORKFLOW                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   1. WRITE                                                                           │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   # main.tf                                                                  │   │
│   │   resource "aws_instance" "web" {                                           │   │
│   │     ami           = "ami-12345678"                                          │   │
│   │     instance_type = "t3.micro"                                              │   │
│   │   }                                                                          │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   2. PLAN                                                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   $ terraform plan                                                           │   │
│   │                                                                              │   │
│   │   Terraform compares:                                                        │   │
│   │   • Your code (desired state)                                               │   │
│   │   • State file (known state)                                                │   │
│   │   • Real infrastructure (actual state)                                      │   │
│   │                                                                              │   │
│   │   Output: "I will create 1 EC2 instance"                                    │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                         │                                            │
│                                         ▼                                            │
│   3. APPLY                                                                           │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   $ terraform apply                                                          │   │
│   │                                                                              │   │
│   │   Terraform:                                                                 │   │
│   │   • Calls AWS API to create instance                                        │   │
│   │   • Waits for creation to complete                                          │   │
│   │   • Updates state file with new resource                                    │   │
│   │                                                                              │   │
│   │   Output: "Apply complete! Resources: 1 added"                              │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### Resources

Resources are the most important element. They describe infrastructure objects.

```hcl
# Resource syntax
resource "PROVIDER_TYPE" "LOCAL_NAME" {
  argument1 = "value1"
  argument2 = "value2"
}

# Example: AWS EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  tags = {
    Name        = "web-server"
    Environment = "production"
  }
}
```

**How to read resource identifiers:**
```
aws_instance.web_server
│      │        │
│      │        └── YOUR name (reference this in other resources)
│      └── Resource TYPE (from provider docs)
└── PROVIDER (aws, google, azurerm, etc.)
```

### Providers

Providers are plugins that Terraform uses to interact with APIs.

```hcl
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  
  # Optional: assume a role
  assume_role {
    role_arn = "arn:aws:iam::123456789:role/TerraformRole"
  }
}

# You can have multiple providers
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Use aliased provider
resource "aws_instance" "west_server" {
  provider = aws.west
  # ...
}
```

### Data Sources

Data sources let you fetch information from outside Terraform.

```hcl
# Fetch existing VPC by name
data "aws_vpc" "existing" {
  tags = {
    Name = "main-vpc"
  }
}

# Use the data in a resource
resource "aws_subnet" "app" {
  vpc_id     = data.aws_vpc.existing.id  # Reference the fetched VPC
  cidr_block = "10.0.1.0/24"
}
```

**Resources vs Data Sources:**

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| Creates infrastructure | ✓ Yes | ✗ No |
| Manages lifecycle | ✓ Yes | ✗ No |
| Read-only | ✗ No | ✓ Yes |
| Use case | Create new | Reference existing |

### Variables

Variables make your configuration reusable.

```hcl
# variables.tf - Define variables
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  default     = [80, 443]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project   = "my-app"
    ManagedBy = "terraform"
  }
}

# main.tf - Use variables
resource "aws_instance" "app" {
  count         = var.instance_count
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  
  tags = merge(var.tags, {
    Name        = "app-${count.index + 1}"
    Environment = var.environment
  })
}
```

**Setting Variables:**

```bash
# 1. Default value in variable definition
# 2. terraform.tfvars file
# 3. *.auto.tfvars files
# 4. Environment variables (TF_VAR_name)
# 5. Command line (-var or -var-file)

# Examples:
terraform apply -var="environment=prod"
terraform apply -var-file="production.tfvars"
export TF_VAR_environment=prod
```

### Outputs

Outputs expose values from your configuration.

```hcl
# outputs.tf
output "instance_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}

output "database_endpoint" {
  description = "Database connection string"
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # Hide in CLI output
}

output "instance_ids" {
  description = "IDs of all instances"
  value       = aws_instance.app[*].id
}
```

**Using Outputs:**
```bash
# View all outputs
terraform output

# View specific output
terraform output instance_ip

# Get output as JSON
terraform output -json
```

---

## HCL Language

### Understanding HCL (HashiCorp Configuration Language)

HCL is purpose-built for defining infrastructure. It balances human readability with machine-parsability.

### Expressions and Types

```hcl
# Primitive types
string_value = "hello"
number_value = 42
bool_value   = true

# Collection types
list_type   = ["a", "b", "c"]
map_type    = { key1 = "value1", key2 = "value2" }
set_type    = toset(["a", "b", "c"])  # No duplicates, no order

# Complex types
object_type = {
  name = "my-app"
  port = 8080
  tags = ["web", "production"]
}

tuple_type = ["string", 42, true]  # Mixed types
```

### References and Interpolation

```hcl
# Reference another resource
resource "aws_eip" "web" {
  instance = aws_instance.web_server.id
  # Format: resource_type.resource_name.attribute
}

# String interpolation
resource "aws_instance" "web" {
  tags = {
    Name = "web-${var.environment}-${count.index}"
    # Produces: "web-prod-0", "web-prod-1", etc.
  }
}

# Heredoc (multi-line strings)
resource "aws_instance" "web" {
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World!"
    yum update -y
  EOF
}
```

### Conditionals

```hcl
# Ternary operator
resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
}

# count for conditional creation
resource "aws_db_instance" "replica" {
  count = var.enable_replica ? 1 : 0  # Create only if enabled
  # ...
}

# for_each with conditionals
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in var.security_rules : rule.name => rule
    if rule.enabled
  }
  # ...
}
```

### Loops

```hcl
# count - for simple iteration
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-${count.index + 1}"  # web-1, web-2, web-3
  }
}

# for_each - for maps and sets
variable "users" {
  default = {
    alice = "admin"
    bob   = "developer"
    carol = "reader"
  }
}

resource "aws_iam_user" "users" {
  for_each = var.users
  name     = each.key  # alice, bob, carol
  tags = {
    Role = each.value  # admin, developer, reader
  }
}

# for expressions - transform data
locals {
  instance_ids = [for i in aws_instance.web : i.id]
  
  upper_names = {
    for name, role in var.users : upper(name) => role
  }
  # { "ALICE" = "admin", "BOB" = "developer", ... }
}
```

### Built-in Functions

```hcl
# String functions
lower("HELLO")              # "hello"
upper("hello")              # "HELLO"
replace("hello", "l", "L")  # "heLLo"
split(",", "a,b,c")         # ["a", "b", "c"]
join("-", ["a", "b", "c"])  # "a-b-c"
format("%s-%03d", "web", 5) # "web-005"

# Collection functions
length(["a", "b", "c"])     # 3
concat([1, 2], [3, 4])      # [1, 2, 3, 4]
flatten([[1, 2], [3, 4]])   # [1, 2, 3, 4]
merge({a = 1}, {b = 2})     # {a = 1, b = 2}
keys({a = 1, b = 2})        # ["a", "b"]
values({a = 1, b = 2})      # [1, 2]
lookup({a = 1}, "a", 0)     # 1 (or 0 if not found)
contains(["a", "b"], "a")   # true

# Numeric functions
max(1, 2, 3)                # 3
min(1, 2, 3)                # 1
ceil(4.3)                   # 5
floor(4.7)                  # 4

# Filesystem functions
file("./script.sh")         # Read file contents
fileexists("./script.sh")   # Check if file exists
templatefile("template.tpl", { name = "world" })

# Encoding functions
base64encode("hello")       # "aGVsbG8="
base64decode("aGVsbG8=")    # "hello"
jsonencode({a = 1, b = 2})  # '{"a":1,"b":2}'
jsondecode('{"a":1}')       # {a = 1}
yamlencode({a = 1})         # "a: 1\n"

# Type conversion
tostring(42)                # "42"
tonumber("42")              # 42
tolist(toset([1, 2, 3]))    # [1, 2, 3]
tomap({a = 1, b = 2})       # {a = 1, b = 2}
```

---

## State Management

### What is State?

State is how Terraform knows what it has created. It's a mapping between your configuration and real-world resources.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           TERRAFORM STATE                                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Your Code (main.tf)              State File (terraform.tfstate)                   │
│   ┌─────────────────────┐          ┌─────────────────────┐                          │
│   │ resource "aws_      │          │ {                   │                          │
│   │   instance" "web" { │   ←───   │   "aws_instance.web": {                        │
│   │   ami = "ami-123"   │   Mapping │     "id": "i-abc123",                          │
│   │   instance_type =   │           │     "ami": "ami-123",                          │
│   │     "t3.micro"      │          │     "public_ip": "54.x.x.x"                   │
│   │ }                   │          │   }                   │                          │
│   └─────────────────────┘          │ }                     │                          │
│                                    └─────────────────────┘                          │
│                                              │                                       │
│                                              ▼                                       │
│                                    Real Infrastructure                              │
│                                    ┌─────────────────────┐                          │
│                                    │  AWS EC2 Instance   │                          │
│                                    │  ID: i-abc123       │                          │
│                                    │  IP: 54.x.x.x       │                          │
│                                    └─────────────────────┘                          │
│                                                                                      │
│   State stores:                                                                      │
│   • Resource IDs (how to find them in the cloud)                                    │
│   • All attributes (even ones not in your code)                                     │
│   • Dependencies (what depends on what)                                             │
│   • Metadata (provider versions, etc.)                                              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Remote State

**Never store state locally in production!**

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/infrastructure.tfstate"
    region         = "us-east-1"
    
    # Encryption
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    
    # Locking (prevents concurrent modifications)
    dynamodb_table = "terraform-locks"
  }
}
```

**Why Remote State?**

| Problem | Solution |
|---------|----------|
| State file lost = infrastructure orphaned | Remote storage is durable |
| Team members overwrite each other | Locking prevents concurrent changes |
| Secrets in state file | Encryption at rest |
| No audit trail | Versioned buckets track history |

### State Commands

```bash
# List resources in state
terraform state list

# Show details of a resource
terraform state show aws_instance.web

# Move a resource to a different address
terraform state mv aws_instance.old aws_instance.new

# Remove a resource from state (without destroying)
terraform state rm aws_instance.legacy

# Import existing infrastructure
terraform import aws_instance.web i-1234567890abcdef0

# Pull remote state locally
terraform state pull

# Force push local state (dangerous!)
terraform state push

# Refresh state from real infrastructure
terraform refresh
```

---

## Modules

### What are Modules?

A module is a container for multiple resources. Every Terraform configuration is a module (the "root module").

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           MODULE BENEFITS                                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Without Modules:                                                                   │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  main.tf (1000+ lines)                                                       │   │
│   │  ├── VPC resources (100 lines)                                              │   │
│   │  ├── Security groups (150 lines)                                            │   │
│   │  ├── EC2 instances (200 lines)                                              │   │
│   │  ├── RDS database (100 lines)                                               │   │
│   │  ├── Load balancer (150 lines)                                              │   │
│   │  └── ... and so on                                                           │   │
│   │                                                                              │   │
│   │  Copy-paste to create staging environment                                    │   │
│   │  Hard to maintain, inconsistencies creep in                                  │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   With Modules:                                                                      │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  modules/                                                                    │   │
│   │  ├── vpc/          (reusable VPC configuration)                             │   │
│   │  ├── security/     (reusable security groups)                               │   │
│   │  ├── compute/      (reusable EC2 patterns)                                  │   │
│   │  └── database/     (reusable RDS patterns)                                  │   │
│   │                                                                              │   │
│   │  environments/                                                               │   │
│   │  ├── prod/         (uses modules with prod settings)                        │   │
│   │  └── staging/      (uses same modules with staging settings)                │   │
│   │                                                                              │   │
│   │  One change in module → updates all environments                            │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Module Structure

```
modules/
└── vpc/
    ├── main.tf       # Resources
    ├── variables.tf  # Input variables
    ├── outputs.tf    # Output values
    └── README.md     # Documentation
```

**modules/vpc/variables.tf:**
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

**modules/vpc/main.tf:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
  }
}
```

**modules/vpc/outputs.tf:**
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}
```

### Using Modules

```hcl
# environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr    = "10.0.0.0/16"
  environment = "production"
}

module "compute" {
  source = "../../modules/compute"
  
  vpc_id     = module.vpc.vpc_id  # Use output from vpc module
  subnet_ids = module.vpc.public_subnet_ids
  
  instance_count = 3
  instance_type  = "t3.large"
}
```

### Public Modules

```hcl
# Terraform Registry modules
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# GitHub modules
module "security" {
  source = "github.com/my-org/terraform-modules//security?ref=v1.0.0"
}
```

---

## Workspaces and Environments

### Managing Multiple Environments

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ENVIRONMENT STRATEGIES                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   OPTION 1: WORKSPACES                                                               │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   Same code, different state                                                 │   │
│   │                                                                              │   │
│   │   main.tf  ────┬──▶ terraform.tfstate.d/dev/                                │   │
│   │                ├──▶ terraform.tfstate.d/staging/                            │   │
│   │                └──▶ terraform.tfstate.d/prod/                               │   │
│   │                                                                              │   │
│   │   Use workspace name in config:                                              │   │
│   │   instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"   │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│   OPTION 2: DIRECTORY PER ENVIRONMENT (Recommended)                                 │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │   environments/                                                              │   │
│   │   ├── dev/                                                                   │   │
│   │   │   ├── main.tf                                                           │   │
│   │   │   ├── terraform.tfvars    # dev settings                                │   │
│   │   │   └── backend.tf          # dev state bucket                            │   │
│   │   ├── staging/                                                               │   │
│   │   │   ├── main.tf                                                           │   │
│   │   │   ├── terraform.tfvars    # staging settings                            │   │
│   │   │   └── backend.tf          # staging state bucket                        │   │
│   │   └── prod/                                                                  │   │
│   │       ├── main.tf                                                           │   │
│   │       ├── terraform.tfvars    # prod settings                               │   │
│   │       └── backend.tf          # prod state bucket                           │   │
│   │                                                                              │   │
│   │   Each environment is isolated, explicit, and auditable                     │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Environment-Specific Variables

```
environments/
├── prod/
│   ├── main.tf
│   └── terraform.tfvars
└── dev/
    ├── main.tf
    └── terraform.tfvars
```

**environments/prod/terraform.tfvars:**
```hcl
environment     = "production"
instance_type   = "t3.large"
instance_count  = 5
enable_backups  = true
enable_multi_az = true
```

**environments/dev/terraform.tfvars:**
```hcl
environment     = "development"
instance_type   = "t3.micro"
instance_count  = 1
enable_backups  = false
enable_multi_az = false
```

---

## Best Practices

### Project Structure

```
terraform/
├── modules/                    # Reusable modules
│   ├── networking/
│   ├── compute/
│   └── database/
├── environments/               # Environment configs
│   ├── dev/
│   ├── staging/
│   └── prod/
├── scripts/                    # Helper scripts
└── README.md
```

### Code Organization

```hcl
# Split into logical files
main.tf         # Primary resources
variables.tf    # Input variables
outputs.tf      # Output values
providers.tf    # Provider configuration
data.tf         # Data sources
locals.tf       # Local values
versions.tf     # Version constraints
```

### Naming Conventions

```hcl
# Resource naming
resource "aws_instance" "web_server" {}      # snake_case
resource "aws_security_group" "app_lb" {}    # descriptive

# Variable naming
variable "instance_count" {}                  # snake_case
variable "enable_monitoring" {}               # boolean: enable_*, is_*, has_*

# Tag naming
tags = {
  Name        = "web-server-prod"            # kebab-case for Name
  Environment = "production"                 # full word
  Project     = "ecommerce"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
}
```

### Security

```hcl
# 1. Never commit secrets
# Use environment variables or secret managers

# 2. Mark sensitive outputs
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}

# 3. Encrypt state at rest
terraform {
  backend "s3" {
    encrypt = true
    kms_key_id = "alias/terraform"
  }
}

# 4. Use IAM roles, not keys
provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::123456789:role/TerraformRole"
  }
}
```

### Version Constraints

```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # Allows 5.x but not 6.0
    }
  }
}
```

---

## Testing Infrastructure

### Testing Levels

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           INFRASTRUCTURE TESTING PYRAMID                             │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│                        /\                                                            │
│                       /  \         End-to-End Tests                                 │
│                      /    \        (Deploy and verify)                              │
│                     /──────\                                                         │
│                    /        \      Integration Tests                                │
│                   /          \     (Module interactions)                            │
│                  /────────────\                                                      │
│                 /              \   Unit Tests                                       │
│                /                \  (terraform validate, tflint)                     │
│               /══════════════════\                                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Static Analysis

```bash
# Built-in validation
terraform validate

# Linting with tflint
tflint

# Security scanning with tfsec
tfsec .

# Compliance checking with Checkov
checkov -d .
```

### Integration Testing with Terratest

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpcModule(t *testing.T) {
    t.Parallel()

    opts := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr":    "10.0.0.0/16",
            "environment": "test",
        },
    }

    // Clean up after test
    defer terraform.Destroy(t, opts)

    // Create infrastructure
    terraform.InitAndApply(t, opts)

    // Verify outputs
    vpcId := terraform.Output(t, opts, "vpc_id")
    assert.Regexp(t, "^vpc-", vpcId)
}
```

This comprehensive guide covers Terraform and Infrastructure as Code from fundamentals to advanced patterns with detailed explanations and examples.
