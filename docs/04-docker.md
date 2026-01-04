# Docker In-Depth Theory

## Container Internals

### How Containers Actually Work

Containers aren't virtual machines. They're **isolated processes** using Linux kernel features:

```
┌────────────────────────────────────────────────────────────────────┐
│                          HOST KERNEL                                │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────┐  ┌─────────────────────┐                  │
│  │     Container A     │  │     Container B     │                  │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │                  │
│  │  │   Namespaces  │  │  │  │   Namespaces  │  │◄── Isolation    │
│  │  │ PID, NET, MNT │  │  │  │ PID, NET, MNT │  │                  │
│  │  └───────────────┘  │  │  └───────────────┘  │                  │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │                  │
│  │  │    Cgroups    │  │  │  │    Cgroups    │  │◄── Resource     │
│  │  │ CPU, Memory   │  │  │  │ CPU, Memory   │  │     Limits      │
│  │  └───────────────┘  │  │  └───────────────┘  │                  │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │                  │
│  │  │   Filesystem  │  │  │  │   Filesystem  │  │◄── Union FS     │
│  │  │  (overlay2)   │  │  │  │  (overlay2)   │  │                  │
│  │  └───────────────┘  │  │  └───────────────┘  │                  │
│  └─────────────────────┘  └─────────────────────┘                  │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### Namespaces (Isolation)

**Namespaces** provide isolation by making resources appear independent:

| Namespace | Isolates |
|-----------|----------|
| **PID** | Process IDs (container sees PID 1 for its main process) |
| **NET** | Network stack (own IP, ports, routes) |
| **MNT** | Mount points (own filesystem view) |
| **UTS** | Hostname and domain |
| **IPC** | Inter-process communication |
| **USER** | User and group IDs |

**Example: See namespaces**
```bash
# List namespaces for a container
docker inspect --format '{{.State.Pid}}' my_container
# Returns: 12345

ls -la /proc/12345/ns/
# lrwxrwxrwx 1 root root 0 Jan 15 10:00 mnt -> 'mnt:[4026532505]'
# lrwxrwxrwx 1 root root 0 Jan 15 10:00 net -> 'net:[4026532508]'
# lrwxrwxrwx 1 root root 0 Jan 15 10:00 pid -> 'pid:[4026532506]'
```

### Cgroups (Resource Limits)

**Control Groups** limit how much CPU, memory, and I/O a container can use:

```bash
# Run with memory limit
docker run -m 512m nginx

# Run with CPU limit (0.5 CPU)
docker run --cpus="0.5" nginx

# Run with both
docker run -m 512m --cpus="1" nginx

# View cgroup settings
docker stats my_container
```

**Under the hood:**
```bash
# Cgroups are mounted at:
ls /sys/fs/cgroup/

# Container limits visible at:
cat /sys/fs/cgroup/memory/docker/<container_id>/memory.limit_in_bytes
```

### Union Filesystem (Layers)

Docker images are built in **layers**. Each instruction creates a new read-only layer.

```
┌────────────────────────────────────────┐
│          Container Layer               │ ← Read-Write
│          (runtime changes)             │
├────────────────────────────────────────┤
│  Layer 5: COPY app.py .                │ ← Read-Only
├────────────────────────────────────────┤
│  Layer 4: RUN pip install flask        │ ← Read-Only  
├────────────────────────────────────────┤
│  Layer 3: WORKDIR /app                 │ ← Read-Only
├────────────────────────────────────────┤
│  Layer 2: RUN apt-get update           │ ← Read-Only
├────────────────────────────────────────┤
│  Layer 1: FROM python:3.11-slim        │ ← Read-Only (base)
└────────────────────────────────────────┘
```

**View layers:**
```bash
# See image layers
docker history nginx:latest

# Output:
# IMAGE          CREATED       CREATED BY                                      SIZE
# a8758716bb6a   2 weeks ago   /bin/sh -c #(nop)  CMD ["nginx" "-g" "daemon…   0B
# <missing>      2 weeks ago   /bin/sh -c #(nop)  STOPSIGNAL SIGQUIT           0B
# <missing>      2 weeks ago   /bin/sh -c #(nop)  EXPOSE 80                    0B
# <missing>      2 weeks ago   /bin/sh -c set -x     && addgroup --system -…   28.5MB
# <missing>      2 weeks ago   /bin/sh -c #(nop)  ENV PKG_RELEASE=1~bookworm   0B
```

---

## Docker Networking Deep Dive

### Network Drivers

| Driver | Use Case | How It Works |
|--------|----------|--------------|
| **bridge** | Default single-host | Virtual bridge connecting containers |
| **host** | Performance-critical | Container uses host network directly |
| **overlay** | Multi-host (Swarm) | VXLAN tunnel between hosts |
| **macvlan** | Legacy apps | Container gets own MAC address |
| **none** | Maximum isolation | No networking |

### Bridge Network Internals

```
┌─────────────────────────────────────────────────────────────────────┐
│                          HOST                                        │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐      ┌───────────────────────┐  │
│  │ Container A  │  │ Container B  │      │    Host Network       │  │
│  │ 172.17.0.2   │  │ 172.17.0.3   │      │    eth0: 192.168.1.x  │  │
│  │     vethXXX ─┼──┼─ vethYYY     │      │                       │  │
│  └──────────────┘  └──────────────┘      └───────────────────────┘  │
│         │                │                         │                 │
│         └────────┬───────┘                         │                 │
│                  │                                 │                 │
│         ┌────────┴────────┐                        │                 │
│         │  docker0 bridge │─── NAT (iptables) ────┘                 │
│         │   172.17.0.1    │                                          │
│         └─────────────────┘                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Practical examples:**

```bash
# Create custom bridge network
docker network create --driver bridge \
  --subnet 10.10.0.0/24 \
  --gateway 10.10.0.1 \
  mynetwork

# Run containers on same network
docker run -d --name web --network mynetwork nginx
docker run -d --name app --network mynetwork python:3.11

# Containers can communicate by name
docker exec app curl http://web  # Works!

# Inspect network
docker network inspect mynetwork

# Connect existing container to additional network
docker network connect mynetwork existing_container
```

### Port Mapping Internals

```bash
# Map port 80 in container to 8080 on host
docker run -p 8080:80 nginx

# What happens:
# 1. Docker creates iptables rules:
sudo iptables -t nat -L DOCKER -n --line-numbers
# DNAT tcp -- 0.0.0.0/0 0.0.0.0/0 tcp dpt:8080 to:172.17.0.2:80

# 2. Incoming traffic to host:8080 → container:80
# 3. Response goes back through NAT
```

---

## Multi-Stage Builds

Multi-stage builds create smaller, more secure images.

### Problem: Large Build Images

```dockerfile
# BAD: 1.2GB image with build tools
FROM python:3.11

# Build dependencies included in final image
RUN apt-get update && apt-get install -y gcc libpq-dev
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
CMD ["python", "app.py"]
```

### Solution: Multi-Stage

```dockerfile
# Stage 1: Build
FROM python:3.11 AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y gcc libpq-dev

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime (smaller image)
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy only the virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY . .

# Run as non-root
RUN useradd -m appuser
USER appuser

EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
```

**Result:** Image size reduced from 1.2GB to ~200MB

---

## Docker Compose Deep Dive

### Complete Example: Full Stack Application

```yaml
# docker-compose.yml
version: '3.8'

# Define named volumes
volumes:
  postgres_data:
  redis_data:

# Define networks
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access

# Define services
services:
  # Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - web
    networks:
      - frontend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Web Application
  web:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        - BUILD_VERSION=${VERSION:-latest}
    image: myapp:${VERSION:-latest}
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY=${SECRET_KEY:?error}  # Required variable
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
    restart: unless-stopped

  # Database
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    secrets:
      - db_password
    restart: unless-stopped

  # Cache
  redis:
    image: redis:alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend
    restart: unless-stopped

  # Background Worker
  worker:
    build: ./app
    command: celery -A tasks worker --loglevel=info
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - backend
    deploy:
      replicas: 3
    restart: unless-stopped

# Secrets (for production)
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Compose Commands

```bash
# Start all services
docker compose up -d

# Scale a service
docker compose up -d --scale worker=5

# View logs
docker compose logs -f web
docker compose logs --tail=100 db

# Execute command in service
docker compose exec web bash
docker compose exec db psql -U user -d myapp

# Stop everything
docker compose down

# Stop and remove volumes
docker compose down -v

# Rebuild and restart
docker compose up -d --build

# View service status
docker compose ps

# Environment override
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Docker Security Best Practices

### 1. Don't Run as Root

```dockerfile
# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser
```

### 2. Use Read-Only Filesystem

```yaml
services:
  web:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

### 3. Limit Capabilities

```yaml
services:
  web:
    image: myapp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if needed
```

### 4. Security Scanning

```bash
# Scan with Docker Scout
docker scout cves myapp:latest

# Scan with Trivy
trivy image myapp:latest

# Scan with Snyk
snyk container test myapp:latest
```

### 5. Use Specific Tags

```dockerfile
# BAD - unpredictable
FROM python:latest

# GOOD - specific version
FROM python:3.11.7-slim-bookworm
```

---

## Real-World Example: Building a Microservices Stack

```bash
# Project structure
myproject/
├── docker-compose.yml
├── services/
│   ├── api/
│   │   ├── Dockerfile
│   │   └── app.py
│   ├── worker/
│   │   ├── Dockerfile
│   │   └── tasks.py
│   └── web/
│       ├── Dockerfile
│       └── src/
├── nginx/
│   └── nginx.conf
└── scripts/
    ├── deploy.sh
    └── backup.sh
```

**Deploy script:**
```bash
#!/bin/bash
set -e

echo "Building images..."
docker compose build

echo "Running tests..."
docker compose run --rm api pytest

echo "Deploying..."
docker compose up -d

echo "Waiting for health checks..."
sleep 10

echo "Verifying..."
curl -f http://localhost/health || exit 1

echo "Deployment complete!"
```
