# Terraform Fundamentals

## What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool that lets you define, provision, and manage infrastructure using declarative configuration files. You describe what you want, and Terraform figures out how to create it.

### Why Infrastructure as Code?

| Traditional | IaC (Terraform) |
|-------------|-----------------|
| Click in web consoles | Write code |
| Undocumented steps | Version-controlled |
| Inconsistent environments | Reproducible |
| Manual scaling | Automated |
| Tribal knowledge | Self-documenting |

### Terraform vs Other Tools

| Tool | Type | Use Case |
|------|------|----------|
| **Terraform** | Provisioning | Create infrastructure (servers, networks) |
| **Ansible** | Configuration | Configure existing infrastructure |
| **Docker** | Packaging | Package applications |
| **Kubernetes** | Orchestration | Run containerized applications |

> **Key Insight**: Terraform **creates** the servers, Ansible **configures** them, Docker **packages** apps, Kubernetes **runs** them.

---

## Core Concepts

### 1. Providers

**Providers** are plugins that allow Terraform to interact with APIs. Each cloud/service has its own provider.

```hcl
# Docker provider (local)
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# AWS provider example
provider "aws" {
  region = "us-west-2"
}

# Kubernetes provider example
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

### 2. Resources

**Resources** are the building blocks - the actual infrastructure to create.

```hcl
# Docker container resource
resource "docker_container" "nginx" {
  name  = "my-nginx"
  image = docker_image.nginx.image_id
  
  ports {
    internal = 80
    external = 8080
  }
}

# Docker image resource
resource "docker_image" "nginx" {
  name = "nginx:latest"
}
```

**Resource Syntax**:
```hcl
resource "<PROVIDER>_<TYPE>" "<NAME>" {
  # Configuration arguments
  argument1 = "value"
  argument2 = "value"
}
```

### 3. State

Terraform maintains a **state file** (`terraform.tfstate`) that maps your configuration to real-world resources. This is how Terraform knows what exists and what to change.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   main.tf       │ ──► │ terraform.tfstate│ ◄── │ Real Resources  │
│   (Desired)     │     │ (Current Known) │     │ (Actual)        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

> ⚠️ **Never manually edit the state file!**

### 4. Variables

Variables make configurations reusable.

**Input Variables** (`variables.tf`):
```hcl
variable "container_name" {
  description = "Name of the Docker container"
  type        = string
  default     = "my-app"
}

variable "external_port" {
  description = "External port to expose"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

**Use Variables**:
```hcl
resource "docker_container" "app" {
  name  = var.container_name
  
  ports {
    external = var.external_port
  }
}
```

**Setting Variables**:
```bash
# terraform.tfvars file
container_name = "production-app"
external_port  = 80

# Command line
terraform apply -var="container_name=my-app"

# Environment variables
export TF_VAR_container_name="my-app"
```

### 5. Outputs

**Outputs** extract information after resources are created.

```hcl
output "container_id" {
  description = "ID of the created container"
  value       = docker_container.app.id
}

output "access_url" {
  description = "URL to access the application"
  value       = "http://localhost:${var.external_port}"
}
```

### 6. Data Sources

**Data sources** fetch information about existing infrastructure.

```hcl
# Get info about an existing Docker network
data "docker_network" "bridge" {
  name = "bridge"
}

# Use it in a resource
resource "docker_container" "app" {
  name  = "my-app"
  image = docker_image.app.image_id
  
  networks_advanced {
    name = data.docker_network.bridge.name
  }
}
```

---

## Terraform Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      TERRAFORM WORKFLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. WRITE          2. INIT           3. PLAN          4. APPLY │
│   ┌─────────┐       ┌─────────┐       ┌─────────┐     ┌────────┐│
│   │ .tf     │ ───►  │ Download│ ───►  │ Preview │ ──► │ Create ││
│   │ files   │       │Providers│       │ Changes │     │ Infra  ││
│   └─────────┘       └─────────┘       └─────────┘     └────────┘│
│                                                                  │
│                                        5. DESTROY                │
│                                        ┌─────────┐               │
│                                        │ Remove  │               │
│                                        │ Infra   │               │
│                                        └─────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

```bash
# Initialize - downloads providers
terraform init

# Format code
terraform fmt

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

---

## Hands-On Lab

### Exercise 1: Provision Nginx with Docker (15 mins)

Create a project directory:
```bash
mkdir -p ~/terraform-lab && cd ~/terraform-lab
```

Create `main.tf`:
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "learning-terraform"

  ports {
    internal = 80
    external = 8080
  }
}

output "container_name" {
  value = docker_container.nginx.name
}

output "url" {
  value = "http://localhost:8080"
}
```

Run it:
```bash
terraform init
terraform plan
terraform apply -auto-approve

# Test it
curl localhost:8080

# View state
terraform show

# Destroy when done
terraform destroy -auto-approve
```

### Exercise 2: Multi-Container Application (25 mins)

Create a full stack with Redis and a Python app.

Create `main.tf`:
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Create a custom network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Redis container
resource "docker_image" "redis" {
  name = "redis:alpine"
}

resource "docker_container" "redis" {
  name  = "redis-cache"
  image = docker_image.redis.image_id
  
  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Web application container
resource "docker_image" "web" {
  name = "hashicorp/http-echo:latest"
}

resource "docker_container" "web" {
  name  = "web-app"
  image = docker_image.web.image_id
  
  command = ["-text=Hello from Terraform!"]
  
  ports {
    internal = 5678
    external = var.web_port
  }
  
  networks_advanced {
    name = docker_network.app_network.name
  }
  
  depends_on = [docker_container.redis]
}

variable "web_port" {
  description = "Port for the web application"
  type        = number
  default     = 9000
}

output "web_url" {
  value = "http://localhost:${var.web_port}"
}
```

Apply and test:
```bash
terraform init
terraform apply -auto-approve

curl localhost:9000

# List containers
docker ps

terraform destroy -auto-approve
```

### Exercise 3: Kubernetes Resources (30 mins)

Deploy to OrbStack's Kubernetes cluster.

Create `kubernetes.tf`:
```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = "terraform-demo"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:alpine"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

output "service_port" {
  value = kubernetes_service.nginx.spec[0].port[0].node_port
}
```

Apply:
```bash
# Ensure Kubernetes is enabled in OrbStack
terraform init
terraform apply -auto-approve

# Check resources
kubectl get all -n terraform-demo

# Cleanup
terraform destroy -auto-approve
```

---

## Best Practices

### File Structure

```
my-infrastructure/
├── main.tf           # Main configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── providers.tf      # Provider configuration
├── terraform.tfvars  # Variable values (don't commit secrets!)
└── modules/          # Reusable modules
    └── web-server/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### State Management

```hcl
# Use remote backend for team collaboration
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Security

1. **Never commit `.tfstate`** - contains sensitive data
2. **Use variables for secrets**
3. **Use `.gitignore`**:
```gitignore
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
```

---

## Further Learning

1. **HashiCorp Learn**: [learn.hashicorp.com/terraform](https://learn.hashicorp.com/terraform)
2. **Terraform Registry**: [registry.terraform.io](https://registry.terraform.io/)
3. **Certification**: HashiCorp Certified Terraform Associate
