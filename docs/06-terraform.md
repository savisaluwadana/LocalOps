# Terraform In-Depth Theory

## Infrastructure as Code Principles

### The IaC Paradigm

**Infrastructure as Code** treats infrastructure the same way developers treat application code:

| Traditional Ops | Infrastructure as Code |
|-----------------|------------------------|
| Manual changes via UI | Declarative config files |
| Undocumented "click ops" | Version controlled |
| Inconsistent environments | Reproducible deployments |
| Risky changes | Safe plan → apply workflow |
| Tribal knowledge | Self-documenting |

### Declarative vs Imperative

**Imperative** (how to do it):
```bash
# Shell script - step by step
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-subnet --vpc-id vpc-123 --cidr-block 10.0.1.0/24
aws ec2 run-instances --image-id ami-123 --count 3
```

**Declarative** (what you want):
```hcl
# Terraform - describe desired state
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-123"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
}
```

---

## How Terraform Works

### The Core Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TERRAFORM WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────┐                                                   │
│   │  .tf Files   │ ◄── Your configuration (desired state)           │
│   └──────┬───────┘                                                   │
│          │ terraform init                                            │
│          ▼                                                           │
│   ┌──────────────┐                                                   │
│   │   Providers  │ ◄── Downloaded plugins (AWS, Docker, K8s)        │
│   └──────┬───────┘                                                   │
│          │ terraform plan                                            │
│          ▼                                                           │
│   ┌──────────────┐     ┌──────────────┐                             │
│   │  Execution   │────►│   Provider   │◄── Real world resources     │
│   │    Plan      │     │     APIs     │                              │
│   └──────┬───────┘     └──────────────┘                             │
│          │ terraform apply                                           │
│          ▼                                                           │
│   ┌──────────────┐                                                   │
│   │    State     │ ◄── terraform.tfstate (current known state)      │
│   │    File      │                                                   │
│   └──────────────┘                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### State Management Deep Dive

The **state file** is Terraform's source of truth about what exists:

```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "mode": "managed",
      "type": "docker_container",
      "name": "nginx",
      "provider": "provider[\"registry.terraform.io/kreuzwerker/docker\"]",
      "instances": [
        {
          "attributes": {
            "id": "abc123...",
            "name": "my-nginx",
            "image": "sha256:def456...",
            "ports": [{"internal": 80, "external": 8080}]
          }
        }
      ]
    }
  ]
}
```

**State operations:**
```bash
# View current state
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show docker_container.nginx

# Move resource to different name
terraform state mv docker_container.old docker_container.new

# Remove from state (doesn't destroy)
terraform state rm docker_container.nginx

# Import existing resource
terraform import docker_container.nginx container_id
```

### Remote State (Team Collaboration)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/infrastructure.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # Prevents concurrent modifications
  }
}
```

---

## Resource Dependencies

### Implicit Dependencies

Terraform automatically detects dependencies:

```hcl
resource "docker_network" "app" {
  name = "app-network"
}

resource "docker_container" "web" {
  name  = "web"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app.name  # Implicit dependency
  }
}
```

### Explicit Dependencies

Use `depends_on` when Terraform can't detect:

```hcl
resource "docker_container" "app" {
  name  = "app"
  image = docker_image.app.image_id

  depends_on = [
    docker_container.db  # Wait for DB to start
  ]
}
```

### Dependency Graph

```bash
# Visualize dependencies
terraform graph | dot -Tpng > graph.png
```

```
┌────────────────────────────────────────────────┐
│              docker_network.app                 │
└─────────────────────┬──────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────────┐    ┌───────────────────┐
│docker_container.db│    │docker_container.web│
└───────────────────┘    └───────────────────┘
        │
        ▼
┌───────────────────┐
│docker_container.app│
└───────────────────┘
```

---

## Variables and Outputs

### Input Variable Types

```hcl
# Basic types
variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

# Complex types
variable "ports" {
  description = "Port mappings"
  type        = list(number)
  default     = [80, 443]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {
    Project = "MyApp"
    Team    = "DevOps"
  }
}

variable "container_config" {
  description = "Container configuration"
  type = object({
    name   = string
    image  = string
    ports  = list(number)
    memory = optional(number, 512)
  })
}

# Sensitive variable
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

### Variable Precedence (lowest to highest)

1. Default values in variable definition
2. `terraform.tfvars` file
3. `*.auto.tfvars` files
4. `-var-file` flag
5. `-var` flag
6. `TF_VAR_*` environment variables

### Outputs

```hcl
output "container_ip" {
  description = "Container IP address"
  value       = docker_container.web.network_data[0].ip_address
}

output "db_connection_string" {
  description = "Database connection string"
  value       = "postgres://${var.db_user}:${var.db_password}@${docker_container.db.name}:5432/${var.db_name}"
  sensitive   = true
}

# Use output from another module
output "api_url" {
  value = module.api.endpoint_url
}
```

---

## Modules

### Module Structure

```
modules/
└── web_app/
    ├── main.tf       # Resources
    ├── variables.tf  # Input variables
    ├── outputs.tf    # Outputs
    └── README.md     # Documentation
```

### Creating a Module

**modules/web_app/main.tf:**
```hcl
resource "docker_network" "app" {
  name = "${var.app_name}-network"
}

resource "docker_image" "app" {
  name = var.image
}

resource "docker_container" "app" {
  count = var.replicas
  name  = "${var.app_name}-${count.index}"
  image = docker_image.app.image_id

  networks_advanced {
    name = docker_network.app.name
  }

  ports {
    internal = var.container_port
    external = var.host_port + count.index
  }

  env = [
    for k, v in var.environment : "${k}=${v}"
  ]
}
```

**modules/web_app/variables.tf:**
```hcl
variable "app_name" {
  type = string
}

variable "image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 80
}

variable "host_port" {
  type    = number
  default = 8080
}

variable "environment" {
  type    = map(string)
  default = {}
}
```

**modules/web_app/outputs.tf:**
```hcl
output "container_names" {
  value = docker_container.app[*].name
}

output "network_name" {
  value = docker_network.app.name
}
```

### Using Modules

```hcl
module "frontend" {
  source = "./modules/web_app"

  app_name       = "frontend"
  image          = "nginx:alpine"
  replicas       = 2
  container_port = 80
  host_port      = 8080
}

module "backend" {
  source = "./modules/web_app"

  app_name       = "backend"
  image          = "python:3.11"
  replicas       = 3
  container_port = 5000
  host_port      = 5000

  environment = {
    DB_HOST = docker_container.postgres.name
    DB_PORT = "5432"
  }
}

# Reference module outputs
output "frontend_containers" {
  value = module.frontend.container_names
}
```

---

## Advanced Patterns

### For_each vs Count

```hcl
# Count - use for identical resources
resource "docker_container" "worker" {
  count = 3
  name  = "worker-${count.index}"
  image = docker_image.worker.image_id
}

# For_each - use for distinct resources
variable "environments" {
  default = {
    dev     = { port = 8080, replicas = 1 }
    staging = { port = 8081, replicas = 2 }
    prod    = { port = 80, replicas = 5 }
  }
}

resource "docker_container" "app" {
  for_each = var.environments

  name  = "app-${each.key}"
  image = docker_image.app.image_id

  ports {
    internal = 80
    external = each.value.port
  }
}

# Access: docker_container.app["prod"].id
```

### Dynamic Blocks

```hcl
variable "ingress_rules" {
  default = [
    { port = 80, cidr = "0.0.0.0/0" },
    { port = 443, cidr = "0.0.0.0/0" },
    { port = 22, cidr = "10.0.0.0/8" }
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }
}
```

### Conditional Resources

```hcl
variable "create_monitoring" {
  type    = bool
  default = true
}

resource "docker_container" "prometheus" {
  count = var.create_monitoring ? 1 : 0

  name  = "prometheus"
  image = docker_image.prometheus.image_id
}

# Reference conditionally created resource
output "prometheus_id" {
  value = var.create_monitoring ? docker_container.prometheus[0].id : null
}
```

---

## Terraform with Docker Example

### Complete Application Stack

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Variables
variable "app_name" {
  default = "myapp"
}

variable "environment" {
  default = "dev"
}

locals {
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Network
resource "docker_network" "app" {
  name   = "${var.app_name}-${var.environment}"
  driver = "bridge"
}

# Database
resource "docker_volume" "postgres_data" {
  name = "${var.app_name}-postgres-data"
}

resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
}

resource "docker_container" "postgres" {
  name  = "${var.app_name}-db"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.app.name
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  env = [
    "POSTGRES_USER=myapp",
    "POSTGRES_PASSWORD=secretpassword",
    "POSTGRES_DB=myapp"
  ]

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U myapp"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  restart = "unless-stopped"
}

# Redis
resource "docker_image" "redis" {
  name = "redis:alpine"
}

resource "docker_container" "redis" {
  name  = "${var.app_name}-redis"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.app.name
  }

  command = ["redis-server", "--appendonly", "yes"]

  restart = "unless-stopped"
}

# Application
resource "docker_image" "app" {
  name = "python:3.11-slim"
}

resource "docker_container" "app" {
  count = 2  # Run 2 replicas
  name  = "${var.app_name}-web-${count.index}"
  image = docker_image.app.image_id

  networks_advanced {
    name = docker_network.app.name
  }

  ports {
    internal = 5000
    external = 5000 + count.index
  }

  env = [
    "DATABASE_URL=postgres://myapp:secretpassword@${docker_container.postgres.name}:5432/myapp",
    "REDIS_URL=redis://${docker_container.redis.name}:6379/0"
  ]

  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]

  restart = "unless-stopped"
}

# Outputs
output "app_urls" {
  value = [
    for container in docker_container.app :
    "http://localhost:${container.ports[0].external}"
  ]
}

output "database_host" {
  value = docker_container.postgres.name
}
```
