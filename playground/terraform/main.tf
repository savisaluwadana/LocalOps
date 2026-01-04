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
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial_nginx"

  ports {
    internal = 80
    external = 8000
  }
}

output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.nginx.id
}

output "url" {
  description = "Access the server at this URL"
  value       = "http://localhost:8000"
}
