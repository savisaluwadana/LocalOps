terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

variable "environment" {
  type    = string
  default = "dev"
}

variable "web_replicas" {
  type    = number
  default = 3
}

locals {
  prefix = "infra-${var.environment}"
}

# Network
resource "docker_network" "main" {
  name = "${local.prefix}-network"
}

# Database
resource "docker_volume" "postgres_data" {
  name = "${local.prefix}-postgres-data"
}

resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
}

resource "docker_container" "postgres" {
  name  = "${local.prefix}-db"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.main.name
  }

  env = [
    "POSTGRES_USER=app",
    "POSTGRES_PASSWORD=secretpassword",
    "POSTGRES_DB=myapp"
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U app"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Redis Cache
resource "docker_image" "redis" {
  name = "redis:alpine"
}

resource "docker_container" "redis" {
  name  = "${local.prefix}-redis"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.main.name
  }

  command = ["redis-server", "--appendonly", "yes"]
}

# Web Servers
resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "web" {
  count = var.web_replicas
  name  = "${local.prefix}-web-${count.index}"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.main.name
  }

  ports {
    internal = 80
    external = 8080 + count.index
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Outputs for Ansible
output "web_container_names" {
  value = docker_container.web[*].name
}

output "web_container_ips" {
  value = docker_container.web[*].network_data[0].ip_address
}

output "web_ports" {
  value = [for c in docker_container.web : c.ports[0].external]
}

output "database_host" {
  value = docker_container.postgres.name
}

output "redis_host" {
  value = docker_container.redis.name
}

output "network_name" {
  value = docker_network.main.name
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = <<-EOF
    [web]
    %{for i, c in docker_container.web~}
    ${c.name} ansible_connection=docker ansible_host=${c.name}
    %{endfor~}

    [database]
    ${docker_container.postgres.name} ansible_connection=docker

    [cache]
    ${docker_container.redis.name} ansible_connection=docker

    [all:vars]
    environment=${var.environment}
    database_host=${docker_container.postgres.name}
    redis_host=${docker_container.redis.name}
  EOF

  filename = "${path.module}/../ansible/inventory.ini"
}
