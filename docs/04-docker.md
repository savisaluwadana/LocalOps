# Docker Fundamentals

## What is Docker?

Docker is a **containerization platform** that packages applications and their dependencies into isolated, portable units called **containers**. Unlike virtual machines, containers share the host OS kernel, making them lightweight and fast.

### Containers vs Virtual Machines

```
┌─────────────────────────────────────────────────────────────┐
│                    VIRTUAL MACHINES                          │
├─────────────────┬─────────────────┬─────────────────────────┤
│      App A      │      App B      │         App C           │
├─────────────────┼─────────────────┼─────────────────────────┤
│   Guest OS      │   Guest OS      │       Guest OS          │
│   (Ubuntu)      │   (CentOS)      │       (Debian)          │
├─────────────────┴─────────────────┴─────────────────────────┤
│                     HYPERVISOR                               │
├─────────────────────────────────────────────────────────────┤
│                     HOST OS                                  │
├─────────────────────────────────────────────────────────────┤
│                     HARDWARE                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      CONTAINERS                              │
├─────────────────┬─────────────────┬─────────────────────────┤
│      App A      │      App B      │         App C           │
├─────────────────┼─────────────────┼─────────────────────────┤
│   Bins/Libs     │   Bins/Libs     │       Bins/Libs         │
├─────────────────┴─────────────────┴─────────────────────────┤
│                   DOCKER ENGINE                              │
├─────────────────────────────────────────────────────────────┤
│                     HOST OS                                  │
├─────────────────────────────────────────────────────────────┤
│                     HARDWARE                                 │
└─────────────────────────────────────────────────────────────┘
```

| Aspect | Containers | VMs |
|--------|------------|-----|
| **Boot Time** | Seconds | Minutes |
| **Size** | MBs | GBs |
| **Performance** | Near-native | Overhead from Guest OS |
| **Isolation** | Process-level | Complete OS isolation |
| **Portability** | Runs anywhere Docker runs | Complex migration |

---

## Core Concepts

### 1. Images

An **image** is a read-only template containing:
- A base OS (Alpine, Ubuntu, etc.)
- Application code
- Dependencies
- Configuration

Images are built in **layers**. Each instruction in a Dockerfile creates a new layer.

```bash
# List local images
docker images

# Pull an image from Docker Hub
docker pull nginx:latest

# Inspect image layers
docker history nginx:latest
```

### 2. Containers

A **container** is a running instance of an image. You can:
- Start/stop containers
- Run multiple containers from the same image
- Each container has its own filesystem, network, and process space

```bash
# Run a container
docker run -d --name my_nginx nginx

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop my_nginx

# Remove a container
docker rm my_nginx
```

### 3. Dockerfile

A **Dockerfile** is a text file with instructions to build an image.

```dockerfile
# Start from a base image
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy dependency file first (for layer caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Document the port (informational)
EXPOSE 8000

# Command to run when container starts
CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t my-python-app .
docker run -d -p 8000:8000 my-python-app
```

### 4. Volumes

**Volumes** persist data beyond container lifecycle.

```bash
# Named volume
docker volume create mydata
docker run -v mydata:/app/data my-app

# Bind mount (host directory)
docker run -v $(pwd)/data:/app/data my-app

# List volumes
docker volume ls
```

### 5. Networks

Docker creates isolated **networks** for container communication.

```bash
# Create a network
docker network create mynetwork

# Run containers on the same network
docker run -d --name db --network mynetwork postgres
docker run -d --name app --network mynetwork my-app

# Containers can now communicate by name
# From 'app': curl http://db:5432
```

---

## Docker Compose

**Docker Compose** defines multi-container applications in a single YAML file.

### Example: Web App with Database

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      - db
    volumes:
      - ./app:/app  # Live reload during development

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

Commands:
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop and remove
docker compose down

# Stop and remove including volumes
docker compose down -v
```

---

## Best Practices

### Dockerfile Optimization

```dockerfile
# BAD: Large image, unnecessary cache
FROM ubuntu:22.04
RUN apt-get update
RUN apt-get install -y python3 python3-pip
COPY . /app
RUN pip3 install -r /app/requirements.txt

# GOOD: Multi-stage, minimal, cached layers
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

### Security

1. **Don't run as root**:
   ```dockerfile
   RUN useradd -m appuser
   USER appuser
   ```

2. **Use specific tags, not `latest`**:
   ```dockerfile
   FROM python:3.11.7-slim  # Good
   FROM python:latest       # Bad
   ```

3. **Scan for vulnerabilities**:
   ```bash
   docker scout cves my-image:latest
   ```

---

## Hands-On Lab

### Exercise 1: Run Your First Container (5 mins)

```bash
# Run nginx and map port 80 to 8080
docker run -d --name web -p 8080:80 nginx

# Visit http://localhost:8080 in your browser

# Check logs
docker logs web

# Stop and remove
docker stop web && docker rm web
```

### Exercise 2: Build a Custom Image (15 mins)

Create a simple Python Flask app:

```bash
mkdir ~/docker-lab && cd ~/docker-lab
```

Create `app.py`:
```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from Docker!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Create `requirements.txt`:
```
flask==3.0.0
```

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t my-flask-app .
docker run -d -p 5000:5000 my-flask-app
curl localhost:5000
```

### Exercise 3: Docker Compose Stack (20 mins)

Create a WordPress stack:

```yaml
# docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: wp_pass
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: wp_pass
      MYSQL_ROOT_PASSWORD: root_secret
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

```bash
docker compose up -d
# Visit http://localhost:8080 to set up WordPress
```

---

## Essential Commands Cheatsheet

```bash
# Images
docker images                    # List images
docker pull <image>              # Download image
docker build -t <name> .         # Build from Dockerfile
docker rmi <image>               # Remove image
docker image prune               # Remove unused images

# Containers
docker run -d -p 80:80 <image>   # Run in background
docker exec -it <container> bash # Shell into container
docker logs -f <container>       # Follow logs
docker stop <container>          # Stop gracefully
docker rm <container>            # Remove container
docker container prune           # Remove stopped containers

# Compose
docker compose up -d             # Start services
docker compose down              # Stop services
docker compose logs -f           # View logs
docker compose ps                # List services

# Cleanup
docker system prune -a           # Remove everything unused
```

---

## Further Learning

1. **Play with Docker**: [labs.play-with-docker.com](https://labs.play-with-docker.com/)
2. **Official Docs**: [docs.docker.com](https://docs.docker.com/)
3. **Book**: "Docker Deep Dive" by Nigel Poulton
