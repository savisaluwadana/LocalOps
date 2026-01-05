# Docker Complete Theory Guide

## Table of Contents

1. [Understanding Containerization](#understanding-containerization)
2. [Docker Architecture](#docker-architecture)
3. [Images Explained](#images-explained)
4. [Containers In-Depth](#containers-in-depth)
5. [Dockerfile Mastery](#dockerfile-mastery)
6. [Docker Networking](#docker-networking)
7. [Storage and Volumes](#storage-and-volumes)
8. [Docker Compose](#docker-compose)
9. [Security Best Practices](#security-best-practices)
10. [Production Considerations](#production-considerations)

---

## Understanding Containerization

### What Problem Does Docker Solve?

Before containers, deploying applications was painful:

**The "Works on My Machine" Problem:**
- Developer writes code on their laptop (macOS, Python 3.9, PostgreSQL 14)
- Tester tests on a different machine (Windows, Python 3.8, PostgreSQL 13)
- Production runs on yet another environment (Linux, Python 3.7, PostgreSQL 12)
- Application fails in production because of subtle differences

**Environment Inconsistency:**
```
Developer Laptop          Test Server              Production
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ macOS 13        │      │ Ubuntu 20.04    │      │ RHEL 8          │
│ Python 3.10     │      │ Python 3.8      │      │ Python 3.6      │
│ pip packages v1 │      │ pip packages v2 │      │ pip packages v3 │
│ Local Redis     │      │ Different Redis │      │ Redis Cluster   │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        ↓                        ↓                        ↓
      Works!               Sometimes works           Crashes! 🔥
```

### Containers vs Virtual Machines

Understanding the difference is crucial:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│            VIRTUAL MACHINES                vs            CONTAINERS                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐      ┌─────────┐ ┌─────────┐ ┌─────────┐     │
│   │  App A  │ │  App B  │ │  App C  │      │  App A  │ │  App B  │ │  App C  │     │
│   ├─────────┤ ├─────────┤ ├─────────┤      ├─────────┤ ├─────────┤ ├─────────┤     │
│   │  Libs   │ │  Libs   │ │  Libs   │      │  Libs   │ │  Libs   │ │  Libs   │     │
│   ├─────────┤ ├─────────┤ ├─────────┤      └────┬────┘ └────┬────┘ └────┬────┘     │
│   │Guest OS │ │Guest OS │ │Guest OS │           └──────────┬┴───────────┘          │
│   │(Ubuntu) │ │(CentOS) │ │(Debian) │                      │                        │
│   └────┬────┘ └────┬────┘ └────┬────┘           ┌──────────▼──────────┐             │
│        └──────────┬┴───────────┘                │   Docker Engine     │             │
│                   │                             │   (Container Runtime)│             │
│        ┌──────────▼──────────┐                  └──────────┬──────────┘             │
│        │    Hypervisor       │                             │                        │
│        │  (VMware, VirtualBox)│                 ┌──────────▼──────────┐             │
│        └──────────┬──────────┘                  │      Host OS         │             │
│                   │                             │      (Linux)         │             │
│        ┌──────────▼──────────┐                  └──────────┬──────────┘             │
│        │     Host OS         │                             │                        │
│        └──────────┬──────────┘                  ┌──────────▼──────────┐             │
│                   │                             │     Hardware         │             │
│        ┌──────────▼──────────┐                  └─────────────────────┘             │
│        │     Hardware        │                                                       │
│        └─────────────────────┘                                                       │
│                                                                                      │
│   CHARACTERISTICS:                           CHARACTERISTICS:                        │
│   • Full OS per VM (gigabytes)               • Shared kernel (megabytes)            │
│   • Boot time: minutes                       • Start time: milliseconds             │
│   • Strong isolation                         • Process-level isolation              │
│   • More resource overhead                   • Near-native performance              │
│   • Hardware virtualization                  • OS-level virtualization              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Key Differences:**

| Aspect | Virtual Machines | Containers |
|--------|------------------|------------|
| **Size** | Gigabytes (includes full OS) | Megabytes (shares host kernel) |
| **Startup** | Minutes | Seconds or less |
| **Performance** | ~5-10% overhead | Near-native |
| **Isolation** | Complete (separate kernel) | Process-level (shared kernel) |
| **Portability** | Machine images are large | Images are small, layered |
| **Use Case** | Run different OSes | Run multiple isolated apps |

### How Containers Work (Linux Fundamentals)

Containers aren't magic—they use existing Linux kernel features:

**1. Namespaces (Isolation)**

Namespaces isolate processes from each other. A container thinks it's the only thing running on the system.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           LINUX NAMESPACES                                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   PID Namespace:     Process isolation                                              │
│   ├── Host sees PIDs 1, 2, 3, ... 12345, 12346 (container processes)               │
│   └── Container sees PIDs 1, 2, 3 (thinks it's the only system)                    │
│                                                                                      │
│   NET Namespace:     Network isolation                                              │
│   ├── Each container gets its own network stack                                    │
│   └── Own IP address, routing table, network devices                               │
│                                                                                      │
│   MNT Namespace:     Filesystem isolation                                           │
│   ├── Container has its own root filesystem                                        │
│   └── Can't see host files (unless explicitly mounted)                             │
│                                                                                      │
│   UTS Namespace:     Hostname isolation                                             │
│   └── Container can have its own hostname                                          │
│                                                                                      │
│   IPC Namespace:     Inter-process communication isolation                          │
│   └── Separate shared memory, semaphores, message queues                           │
│                                                                                      │
│   USER Namespace:    User ID isolation                                              │
│   └── UID 0 in container can map to non-root on host                               │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**2. Control Groups (cgroups) - Resource Limits**

cgroups limit how much CPU, memory, and I/O a container can use:

```bash
# Container A gets max 50% CPU and 512MB RAM
# Even if it tries to use more, the kernel prevents it

Container A: CPU: 0.5 cores, Memory: 512MB, I/O: 100MB/s
Container B: CPU: 2 cores, Memory: 2GB, I/O: 500MB/s
```

**3. Union Filesystems (Overlay)**

Containers use layered filesystems that are efficient and fast:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        CONTAINER FILESYSTEM LAYERS                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Container View (merged)              How it's stored                              │
│   ┌─────────────────────┐              ┌─────────────────────┐                      │
│   │ /app/data.txt       │              │ CONTAINER LAYER     │ ← Writable           │
│   │ /app/code.py        │              │ (changes only)      │                      │
│   │ /usr/bin/python     │              ├─────────────────────┤                      │
│   │ /bin/bash           │              │ APP LAYER           │ ← Read-only          │
│   │ /etc/passwd         │              │ COPY app/ /app      │                      │
│   └─────────────────────┘              ├─────────────────────┤                      │
│                                        │ PYTHON LAYER        │ ← Read-only          │
│   Container sees one                   │ RUN pip install     │                      │
│   merged filesystem                    ├─────────────────────┤                      │
│                                        │ BASE LAYER          │ ← Read-only          │
│                                        │ ubuntu:22.04        │                      │
│                                        └─────────────────────┘                      │
│                                                                                      │
│   When container writes a file, it goes to the container layer only                │
│   Base layers are SHARED between all containers using that image!                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Docker Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DOCKER ARCHITECTURE                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   CLIENT                        DOCKER HOST                     REGISTRY             │
│   ┌─────────────┐              ┌──────────────────────────┐    ┌──────────────┐     │
│   │  docker CLI │──────────────│     Docker Daemon        │────│ Docker Hub   │     │
│   │             │   REST API   │     (dockerd)            │    │              │     │
│   │  docker     │              │                          │    │ ┌──────────┐ │     │
│   │  build      │              │  ┌────────────────────┐  │    │ │  nginx   │ │     │
│   │  pull       │              │  │     containerd     │  │    │ │  redis   │ │     │
│   │  run        │              │  │ (container runtime)│  │    │ │  mysql   │ │     │
│   │  push       │              │  └─────────┬──────────┘  │    │ │  your-app│ │     │
│   │  ...        │              │            │             │    │ └──────────┘ │     │
│   └─────────────┘              │  ┌─────────▼──────────┐  │    └──────────────┘     │
│                                │  │      runc          │  │                          │
│                                │  │ (creates containers)│  │                          │
│                                │  └─────────┬──────────┘  │                          │
│                                │            │             │                          │
│                                │  ┌─────────▼──────────┐  │                          │
│                                │  │    CONTAINERS      │  │                          │
│                                │  │ ┌────┐ ┌────┐     │  │                          │
│                                │  │ │ C1 │ │ C2 │ ... │  │                          │
│                                │  │ └────┘ └────┘     │  │                          │
│                                │  └────────────────────┘  │                          │
│                                └──────────────────────────┘                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Component Details

**Docker Client (docker CLI)**
- What you interact with directly
- Sends commands to the Docker daemon via REST API
- Can communicate with remote Docker daemons

**Docker Daemon (dockerd)**
- Background service that manages Docker objects
- Listens for Docker API requests
- Manages images, containers, networks, volumes
- Can communicate with other daemons

**containerd**
- Industry-standard container runtime
- Manages container lifecycle (start, stop, pause)
- Handles image transfer and storage

**runc**
- Low-level runtime that actually creates containers
- Implements OCI (Open Container Initiative) specs
- Creates namespaces and cgroups

**Registry**
- Stores Docker images
- Docker Hub is the default public registry
- You can run private registries

---

## Images Explained

### What is a Docker Image?

An image is a read-only template for creating containers. Think of it as:
- A class (image) vs an instance (container) in programming
- A recipe (image) vs a cake (container) in cooking

**Image Characteristics:**
- Immutable (can't be changed once built)
- Composed of layers
- Can be tagged with versions
- Stored in registries

### Image Layers

Every instruction in a Dockerfile creates a layer:

```dockerfile
# Each line creates a new layer
FROM ubuntu:22.04              # Layer 1: Base OS (70MB)
RUN apt-get update             # Layer 2: Updated package lists (30MB)
RUN apt-get install -y python3 # Layer 3: Python installed (50MB)
COPY app.py /app/              # Layer 4: Your code (1KB)
```

**Why Layers Matter:**

1. **Caching**: If you change only `app.py`, Docker only rebuilds Layer 4
2. **Sharing**: Multiple images based on `ubuntu:22.04` share Layer 1
3. **Efficiency**: Only changed layers are transmitted when pushing/pulling

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           LAYER SHARING EXAMPLE                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Image A (Web App)              Image B (API)                                       │
│   ┌─────────────────┐           ┌─────────────────┐                                 │
│   │ COPY webapp     │ ← Unique  │ COPY api        │ ← Unique                        │
│   ├─────────────────┤           ├─────────────────┤                                 │
│   │ npm install     │ ← Unique  │ pip install     │ ← Unique                        │
│   ├─────────────────┤           ├─────────────────┤                                 │
│   │ Node.js         │ ← Unique  │ Python          │ ← Unique                        │
│   ├─────────────────┤           ├─────────────────┤                                 │
│   │    ubuntu:22.04 ├───────────┤ ubuntu:22.04    │ ← SHARED! (stored once)         │
│   └─────────────────┘           └─────────────────┘                                 │
│                                                                                      │
│   Storage savings: Base layer stored only once, even with 100 images using it      │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Image Naming and Tags

```
registry/repository:tag

docker.io/library/nginx:1.25.3-alpine
└──┬───┘ └──┬───┘ └─┬─┘ └─────┬──────┘
   │       │       │         │
 Registry  Namespace  Image   Tag

Examples:
nginx                         = docker.io/library/nginx:latest
nginx:1.25                    = docker.io/library/nginx:1.25
mycompany/api:v2.1.0          = docker.io/mycompany/api:v2.1.0
gcr.io/project/myapp:abc123   = Google Container Registry image
```

### Working with Images

```bash
# Search for images
docker search nginx

# Pull an image
docker pull nginx:1.25-alpine

# List local images
docker images
docker image ls

# Inspect image details
docker image inspect nginx:1.25-alpine

# View image history (layers)
docker history nginx:1.25-alpine

# Remove an image
docker rmi nginx:1.25-alpine
docker image rm nginx:1.25-alpine

# Remove unused images
docker image prune
docker image prune -a  # Remove all unused (not just dangling)

# Tag an image
docker tag myapp:latest mycompany/myapp:v1.0

# Push to registry
docker push mycompany/myapp:v1.0
```

---

## Containers In-Depth

### Container Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           CONTAINER LIFECYCLE                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│                         ┌─────────────┐                                              │
│              create     │             │    start                                     │
│   Image ────────────────│   Created   │──────────────────┐                          │
│                         │             │                  │                           │
│                         └─────────────┘                  ▼                           │
│                                                   ┌─────────────┐                    │
│                                                   │             │                    │
│                         ┌─────────────┐  start    │   Running   │                    │
│                         │   Stopped   │◀──────────│             │                    │
│                         │  (Exited)   │           └──────┬──────┘                    │
│                         │             │  stop            │                           │
│                         │             │──────────────────┘                           │
│                         └──────┬──────┘                                              │
│                                │ rm                pause    unpause                  │
│                                │           ┌──────────────────────────┐              │
│                                ▼           ▼          restart         │              │
│                         ┌─────────────┐  ┌─────────────┐              │              │
│                         │             │  │             │              │              │
│                         │   Removed   │  │   Paused    │──────────────┘              │
│                         │  (Deleted)  │  │   (Frozen)  │                             │
│                         └─────────────┘  └─────────────┘                             │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Running Containers

```bash
# Basic run (foreground, attached)
docker run nginx

# Run in background (detached)
docker run -d nginx

# Run with a name
docker run -d --name my-nginx nginx

# Interactive terminal (useful for debugging)
docker run -it ubuntu:22.04 bash

# Automatically remove when stopped
docker run --rm nginx

# Port mapping
docker run -d -p 8080:80 nginx
# Host port 8080 → Container port 80

# Volume mount
docker run -d -v /host/path:/container/path nginx

# Environment variables
docker run -d -e DATABASE_URL=postgres://... myapp

# Resource limits
docker run -d --memory=512m --cpus=0.5 myapp

# Combined example
docker run -d \
    --name production-api \
    -p 8080:3000 \
    -v $(pwd)/config:/app/config:ro \
    -v app-data:/app/data \
    -e NODE_ENV=production \
    -e DATABASE_URL=postgres://... \
    --memory=1g \
    --cpus=1.5 \
    --restart unless-stopped \
    myapp:v1.2.3
```

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container (graceful shutdown)
docker stop my-container

# Kill a container (immediate)
docker kill my-container

# Restart a container
docker restart my-container

# Pause/unpause (freeze processes)
docker pause my-container
docker unpause my-container

# Remove a container
docker rm my-container
docker rm -f my-container  # Force remove running container

# Remove all stopped containers
docker container prune

# View logs
docker logs my-container
docker logs -f my-container         # Follow (live)
docker logs --tail 100 my-container # Last 100 lines
docker logs --since 1h my-container # Last hour

# Execute command in running container
docker exec my-container ls /app
docker exec -it my-container bash   # Interactive shell

# Copy files
docker cp file.txt my-container:/app/
docker cp my-container:/app/log.txt ./

# Inspect container details
docker inspect my-container

# View resource usage
docker stats
docker stats my-container
```

### Container States Explained

| State | Description | Cause |
|-------|-------------|-------|
| **Created** | Container exists but never started | `docker create` |
| **Running** | Main process is executing | `docker start/run` |
| **Paused** | Processes frozen in memory | `docker pause` |
| **Exited** | Main process has stopped | Process finished or crashed |
| **Dead** | Docker couldn't stop it cleanly | System issues |

---

## Dockerfile Mastery

### What is a Dockerfile?

A Dockerfile is a text file with instructions to build an image. It's like a recipe that Docker follows step by step.

### Dockerfile Instructions Explained

```dockerfile
# ─────────────────────────────────────────────────────────────────────────────
# FROM - Base image to start from (required, must be first)
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04
# Use specific tags, never :latest in production

FROM python:3.11-slim
# Slim variants are smaller (no dev tools)

FROM node:18-alpine
# Alpine variants are smallest (~5MB base)

FROM scratch
# Empty image, for minimal containers


# ─────────────────────────────────────────────────────────────────────────────
# LABEL - Metadata about the image
# ─────────────────────────────────────────────────────────────────────────────
LABEL maintainer="team@example.com"
LABEL version="1.0"
LABEL description="Production web application"


# ─────────────────────────────────────────────────────────────────────────────
# ENV - Set environment variables
# ─────────────────────────────────────────────────────────────────────────────
ENV NODE_ENV=production
ENV APP_HOME=/app
ENV PATH="${APP_HOME}/bin:${PATH}"

# These persist in the running container


# ─────────────────────────────────────────────────────────────────────────────
# ARG - Build-time variables (not in running container)
# ─────────────────────────────────────────────────────────────────────────────
ARG VERSION=1.0.0
ARG BUILD_DATE

# Pass during build: docker build --build-arg VERSION=2.0.0 .


# ─────────────────────────────────────────────────────────────────────────────
# WORKDIR - Set working directory
# ─────────────────────────────────────────────────────────────────────────────
WORKDIR /app
# All subsequent commands run from here
# Creates directory if it doesn't exist


# ─────────────────────────────────────────────────────────────────────────────
# COPY - Copy files from build context to image
# ─────────────────────────────────────────────────────────────────────────────
COPY package.json package-lock.json ./
# COPY <source> <destination>

COPY . .
# Copy everything (respect .dockerignore)

COPY --chown=appuser:appgroup app/ /app/
# Copy with ownership


# ─────────────────────────────────────────────────────────────────────────────
# ADD - Like COPY, but with extra features
# ─────────────────────────────────────────────────────────────────────────────
ADD https://example.com/file.tar.gz /tmp/
# Can download from URLs

ADD archive.tar.gz /app/
# Automatically extracts tar archives

# Prefer COPY unless you need ADD's features


# ─────────────────────────────────────────────────────────────────────────────
# RUN - Execute commands during build
# ─────────────────────────────────────────────────────────────────────────────
# Shell form (runs in /bin/sh -c)
RUN apt-get update && apt-get install -y nginx

# Exec form (no shell processing)
RUN ["apt-get", "update"]

# Multi-line for readability
RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-pip \
        build-essential && \
    rm -rf /var/lib/apt/lists/*  # Clean up apt cache


# ─────────────────────────────────────────────────────────────────────────────
# USER - Switch user for subsequent commands
# ─────────────────────────────────────────────────────────────────────────────
RUN useradd --create-home appuser
USER appuser
# All following commands run as appuser


# ─────────────────────────────────────────────────────────────────────────────
# EXPOSE - Document which ports the container listens on
# ─────────────────────────────────────────────────────────────────────────────
EXPOSE 80
EXPOSE 443
EXPOSE 8080/tcp
EXPOSE 5432/udp

# This is documentation only - doesn't actually publish ports
# You still need -p flag when running


# ─────────────────────────────────────────────────────────────────────────────
# VOLUME - Create mount point for external data
# ─────────────────────────────────────────────────────────────────────────────
VOLUME /app/data
VOLUME ["/var/log", "/var/cache"]

# Data in these paths persists even if container is removed


# ─────────────────────────────────────────────────────────────────────────────
# CMD - Default command when container starts
# ─────────────────────────────────────────────────────────────────────────────
CMD ["python", "app.py"]
# Exec form (preferred)

CMD python app.py
# Shell form

# Can be overridden at runtime:
# docker run myimage python other_script.py


# ─────────────────────────────────────────────────────────────────────────────
# ENTRYPOINT - Container's main executable
# ─────────────────────────────────────────────────────────────────────────────
ENTRYPOINT ["python", "app.py"]
# Can't be overridden (without --entrypoint flag)

ENTRYPOINT ["python"]
CMD ["app.py"]
# ENTRYPOINT + CMD combine:
# docker run myimage           → python app.py
# docker run myimage test.py   → python test.py


# ─────────────────────────────────────────────────────────────────────────────
# HEALTHCHECK - Define container health check
# ─────────────────────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

### Multi-Stage Builds

Multi-stage builds are one of Docker's most powerful features for creating production-ready container images. They allow you to use multiple FROM statements in a single Dockerfile, where each FROM begins a new stage. You can selectively copy artifacts from one stage to another, leaving behind everything you don't need in the final image.

#### How Multi-Stage Builds Work

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     MULTI-STAGE BUILD ARCHITECTURE                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   STAGE 1: Build          STAGE 2: Test           STAGE 3: Production               │
│   ┌──────────────┐       ┌──────────────┐        ┌──────────────┐                  │
│   │ FROM node:18 │       │FROM node:18  │        │FROM node:18  │                  │
│   │              │       │              │        │   -alpine    │                  │
│   │ Install deps │       │ Copy from    │        │              │                  │
│   │ Build tools  │──────▶│   builder    │        │ COPY --from  │                  │
│   │ Compile code │       │              │        │   =builder   │                  │
│   │              │       │ Run tests    │        │   /app/dist  │                  │
│   │ Size: 1.2GB  │       │              │        │              │                  │
│   └──────────────┘       │ Size: 1.3GB  │        │ Only runtime │                  │
│         │                └──────────────┘        │              │                  │
│         │                       │                │ Size: 150MB  │                  │
│         │                       │                └──────────────┘                  │
│         └───────────────────────┴────────────────────────▶                          │
│                                                                                      │
│   Only the FINAL stage becomes the image!                                           │
│   Previous stages are discarded (but cached for rebuilds)                          │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

#### Key Benefits

**1. Dramatically Smaller Images**
- Remove build tools, compilers, and intermediate artifacts
- Production images contain only runtime dependencies
- 10x-100x size reduction is common

**2. Enhanced Security**
- No build tools in production images = smaller attack surface
- Reduced vulnerability exposure
- Separation of build-time and runtime secrets

**3. Improved Build Performance**
- Docker caches each stage independently
- Rebuilds only what changed
- Parallel builds of independent stages

**4. Cleaner Dockerfiles**
- One file for all environments (build, test, production)
- No need for complex build scripts
- Self-documenting build process

#### Example 1: Node.js/TypeScript Application

From development to production-ready in one Dockerfile:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Dependencies (cached layer for node_modules)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS dependencies

WORKDIR /app

# Copy only package files to leverage cache
COPY package.json package-lock.json ./

# Install ALL dependencies (including devDependencies)
RUN npm ci

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Builder (compile TypeScript to JavaScript)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS builder

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy source code
COPY . .

# Build the application (TypeScript → JavaScript)
RUN npm run build

# TypeScript files, test files, and configs are now in dist/
# But we also have node_modules with devDependencies we don't need

# ═════════════════════════════════════════════════════════════════════════════
# Stage 3: Production Dependencies (only runtime dependencies)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS prod-dependencies

WORKDIR /app

COPY package.json package-lock.json ./

# Install ONLY production dependencies (no devDependencies)
RUN npm ci --only=production

# ═════════════════════════════════════════════════════════════════════════════
# Stage 4: Production (minimal runtime image)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only production dependencies
COPY --from=prod-dependencies /app/node_modules ./node_modules

# Copy only the compiled JavaScript (not TypeScript source)
COPY --from=builder /app/dist ./dist

# Copy runtime config files
COPY package.json ./

# Switch to non-root user
USER appuser

# Document exposed port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["node", "dist/server.js"]

# ═════════════════════════════════════════════════════════════════════════════
# Size Comparison:
# ─────────────────────────────────────────────────────────────────────────────
# Single-stage with node:18        : ~1,200 MB  (includes TS compiler, devDeps)
# Multi-stage with node:18-alpine  :   ~150 MB  (only runtime + compiled code)
# Reduction                         :   ~88%    (8x smaller!)
# ═════════════════════════════════════════════════════════════════════════════
```

#### Example 2: Python/Flask Application

Separating compilation from runtime for Python packages:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Builder (compile dependencies with native extensions)
# ═════════════════════════════════════════════════════════════════════════════
FROM python:3.11 AS builder

WORKDIR /app

# Install build dependencies for compiling Python packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    build-essential \
    libpq-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install dependencies to a specific directory
# Using --prefix to install to /install directory
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Production (minimal runtime environment)
# ═════════════════════════════════════════════════════════════════════════════
FROM python:3.11-slim AS production

WORKDIR /app

# Install only runtime dependencies (not build tools)
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Set Python to run in unbuffered mode (better for Docker logs)
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')"

CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]

# ═════════════════════════════════════════════════════════════════════════════
# Size Comparison:
# ─────────────────────────────────────────────────────────────────────────────
# Single-stage with python:3.11     :   ~1,000 MB  (includes gcc, g++, etc.)
# Multi-stage with python:3.11-slim :     ~200 MB  (only runtime libraries)
# Reduction                          :     ~80%    (5x smaller!)
# ═════════════════════════────────════════════════════════════════════════════
```

#### Example 3: Go Application (Extreme Size Reduction)

Go compiles to a single static binary, enabling the smallest possible images:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Builder (compile Go binary)
# ═════════════════════════════════════════════════════════════════════════════
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git (needed for go modules)
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies (cached if go.mod hasn't changed)
RUN go mod download

# Copy source code
COPY . .

# Build the binary
# CGO_ENABLED=0 creates a fully static binary (no C dependencies)
# -ldflags="-w -s" strips debug information for smaller binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Production (scratch - absolutely minimal)
# ═════════════════════════════════════════════════════════════════════════════
FROM scratch AS production

# Copy CA certificates for HTTPS requests
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binary (this is ALL we need!)
COPY --from=builder /app/server /server

# Copy any static files if needed
# COPY --from=builder /app/static /static

# Document port
EXPOSE 8080

# No shell, no package manager, no utilities - just our binary
# This is as minimal as it gets!
ENTRYPOINT ["/server"]

# ═════════════════════════════════════════════════════════════════════════════
# Size Comparison:
# ─────────────────────────────────────────────────────────────────────────────
# Single-stage with golang:1.21      :   ~800 MB  (Go toolchain + stdlib)
# Multi-stage with scratch           :    ~10 MB  (just the compiled binary!)
# Reduction                           :   ~98%    (80x smaller!)
# ═════════════════════════════════════════════════════════════════════════════
#
# Note: If you need a shell for debugging, use alpine instead of scratch:
# FROM alpine:3.18
# RUN apk add --no-cache ca-certificates
# ...
# This adds ~5MB but gives you a shell and basic tools
# ═════════════════════════════════════════════════════════════════════════════
```

#### Example 4: Java/Spring Boot Application

Maven/Gradle builds produce large artifacts; multi-stage builds keep only what's needed:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Dependencies (cache Maven dependencies separately)
# ═════════════════════════════════════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-17 AS dependencies

WORKDIR /app

# Copy only POM file to cache dependencies
COPY pom.xml .

# Download dependencies (cached if pom.xml hasn't changed)
RUN mvn dependency:go-offline -B

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Builder (compile and package application)
# ═════════════════════════════════════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=dependencies /root/.m2 /root/.m2

# Copy source code
COPY pom.xml .
COPY src ./src

# Build the application (skip tests in build, run them separately)
RUN mvn clean package -DskipTests -B

# The JAR file is now in target/*.jar

# ═════════════════════════════════════════════════════════════════════════════
# Stage 3: Production (JRE only, no JDK or Maven)
# ═════════════════════════════════════════════════════════════════════════════
FROM eclipse-temurin:17-jre-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring

# Copy only the JAR file from builder
COPY --from=builder /app/target/*.jar app.jar

# Switch to non-root user
USER spring

EXPOSE 8080

# Health check using Spring Boot Actuator
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

# Optional: JVM tuning for containers
# ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]

# ═════════════════════════════════════════════════════════════════════════════
# Size Comparison:
# ─────────────────────────────────────────────────────────────────────────────
# Single-stage with Maven + JDK     :  ~850 MB  (Maven + JDK + .m2 cache)
# Multi-stage with JRE-alpine       :  ~200 MB  (JRE + JAR only)
# Reduction                          :  ~76%    (4x smaller!)
# ═════════════════════════════════════════════════════════════════════════════
```

#### Example 5: React/TypeScript Frontend

Building static assets and serving with nginx:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Dependencies
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS dependencies

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Builder (build React app)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS builder

WORKDIR /app

# Copy dependencies
COPY --from=dependencies /app/node_modules ./node_modules

# Copy source
COPY . .

# Build production bundle
# This creates optimized static files in /app/build
ENV NODE_ENV=production
RUN npm run build

# Result: build/ contains HTML, CSS, JS bundles

# ═════════════════════════════════════════════════════════════════════════════
# Stage 3: Production (nginx to serve static files)
# ═════════════════════════════════════════════════════════════════════════════
FROM nginx:1.25-alpine AS production

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built static files from builder
# nginx serves files from /usr/share/nginx/html by default
COPY --from=builder /app/build /usr/share/nginx/html

# Add custom error pages
COPY error-pages/ /usr/share/nginx/html/errors/

# Create non-root user (nginx alpine runs as nginx user by default)
# Just verify it exists
RUN id nginx

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# nginx.conf should be configured to run as non-root
CMD ["nginx", "-g", "daemon off;"]

# ═════════════════════════════════════════════════════════════════════════════
# Size Comparison:
# ─────────────────────────────────────────────────────────────────────────────
# Single-stage with node:18          :  ~1,200 MB  (Node + npm + build tools)
# Multi-stage with nginx:alpine      :     ~40 MB  (nginx + static files only)
# Reduction                           :    ~96%    (30x smaller!)
# ═════════════════════════════────════════════════════════════════════════════
```

#### Example 6: Monorepo with Multiple Services

Building multiple services from a monorepo, sharing common stages:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# Stage 1: Base dependencies (shared by all services)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18 AS base

WORKDIR /app

# Copy root package files
COPY package.json package-lock.json ./
COPY packages/shared/package.json ./packages/shared/

# Install all dependencies
RUN npm ci

# ═════════════════════════════════════════════════════════════════════════════
# Stage 2: Build shared library
# ═════════════════════════════════════════════════════════════════════════════
FROM base AS shared-builder

COPY packages/shared ./packages/shared
RUN cd packages/shared && npm run build

# ═════════════════════════════════════════════════════════════════════════════
# Stage 3: Build API service
# ═════════════════════════════════════════════════════════════════════════════
FROM base AS api-builder

# Copy built shared library
COPY --from=shared-builder /app/packages/shared/dist ./packages/shared/dist

# Copy and build API service
COPY packages/api ./packages/api
RUN cd packages/api && npm run build

# ═════════════════════════════════════════════════════════════════════════════
# Stage 4: Build Web service
# ═════════════════════════════════════════════════════════════════════════════
FROM base AS web-builder

# Copy built shared library
COPY --from=shared-builder /app/packages/shared/dist ./packages/shared/dist

# Copy and build Web service
COPY packages/web ./packages/web
RUN cd packages/web && npm run build

# ═════════════════════════════════════════════════════════════════════════════
# Stage 5: API Production (can be built with --target api-production)
# ═════════════════════════════════════════════════════════════════════════════
FROM node:18-alpine AS api-production

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only API artifacts
COPY --from=api-builder /app/packages/api/dist ./dist
COPY --from=api-builder /app/packages/shared/dist ./shared
COPY --from=base /app/node_modules ./node_modules

USER appuser
EXPOSE 3000
CMD ["node", "dist/server.js"]

# ═════════════════════════════════════════════════════════════════════════════
# Stage 6: Web Production (can be built with --target web-production)
# ═════════════════════════════════════════════════════════════════════════════
FROM nginx:1.25-alpine AS web-production

# Copy only Web static files
COPY --from=web-builder /app/packages/web/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# ═════════════════════════════════════════════════════════════════════════════
# Build specific services using --target:
# ─────────────────────────────────────────────────────────────────────────────
# docker build --target api-production -t myapp-api .
# docker build --target web-production -t myapp-web .
# ═════════════════════════════════════════════════════════════════════════════
```

#### Advanced Patterns

**1. Using the `--target` Flag**

Build only a specific stage for testing or deployment:

```bash
# Build only the builder stage (for testing build process)
docker build --target builder -t myapp:builder .

# Build only production stage (default)
docker build --target production -t myapp:latest .

# Build test stage with different configurations
docker build --target test --build-arg ENV=staging -t myapp:test .
```

**2. Copying from External Images**

You can copy files from any image, not just previous stages:

```dockerfile
# Copy nginx configuration from official nginx image
FROM scratch AS production
COPY --from=nginx:1.25 /etc/nginx/nginx.conf /etc/nginx/

# Copy certificates from a specific image
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from tool images
COPY --from=hashicorp/terraform:latest /bin/terraform /usr/local/bin/
```

**3. Named Stages as Build Arguments**

Make stages flexible with build arguments:

```dockerfile
ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION} AS builder

ARG BASE_IMAGE=python:3.11-slim
FROM ${BASE_IMAGE} AS production

# Build with: docker build --build-arg PYTHON_VERSION=3.10 .
```

**4. Layer Caching Strategies**

Understanding cache behavior with multi-stage builds:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     MULTI-STAGE BUILD CACHING                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   First Build (all layers built):                                                   │
│   ┌──────────────────────────────────────────────────────────────┐                  │
│   │ Stage 1: dependencies                                         │                  │
│   │   FROM node:18                           [PULL]    5 sec     │                  │
│   │   COPY package.json                      [BUILD]   1 sec     │                  │
│   │   RUN npm ci                             [BUILD]  45 sec     │  Cache layer A   │
│   ├──────────────────────────────────────────────────────────────┤                  │
│   │ Stage 2: builder                                              │                  │
│   │   FROM node:18                           [CACHE]   0 sec     │                  │
│   │   COPY --from=dependencies               [BUILD]   2 sec     │                  │
│   │   COPY src/                              [BUILD]   1 sec     │                  │
│   │   RUN npm run build                      [BUILD]  30 sec     │  Cache layer B   │
│   ├──────────────────────────────────────────────────────────────┤                  │
│   │ Stage 3: production                                           │                  │
│   │   FROM node:18-alpine                    [PULL]    3 sec     │                  │
│   │   COPY --from=builder /app/dist          [BUILD]   1 sec     │  Cache layer C   │
│   └──────────────────────────────────────────────────────────────┘                  │
│                                                                                      │
│   Second Build (code changed, package.json same):                                   │
│   ┌──────────────────────────────────────────────────────────────┐                  │
│   │ Stage 1: dependencies                                         │                  │
│   │   FROM node:18                           [CACHE]   0 sec  ✓  │                  │
│   │   COPY package.json                      [CACHE]   0 sec  ✓  │                  │
│   │   RUN npm ci                             [CACHE]   0 sec  ✓  │  Use layer A     │
│   ├──────────────────────────────────────────────────────────────┤                  │
│   │ Stage 2: builder                                              │                  │
│   │   FROM node:18                           [CACHE]   0 sec  ✓  │                  │
│   │   COPY --from=dependencies               [CACHE]   0 sec  ✓  │                  │
│   │   COPY src/                              [BUILD]   1 sec  ⚠  │  Changed!        │
│   │   RUN npm run build                      [BUILD]  30 sec     │  Rebuild         │
│   ├──────────────────────────────────────────────────────────────┤                  │
│   │ Stage 3: production                                           │                  │
│   │   FROM node:18-alpine                    [CACHE]   0 sec  ✓  │                  │
│   │   COPY --from=builder /app/dist          [BUILD]   1 sec     │  New artifacts   │
│   └──────────────────────────────────────────────────────────────┘                  │
│                                                                                      │
│   Build time: First: ~88s, Second: ~32s (64% faster!)                              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**5. Build-Time vs Runtime Dependencies**

Clear separation improves security and size:

```dockerfile
# ═════════════════════════════════════════════════════════════════════════════
# BUILD-TIME DEPENDENCIES (only in builder stage)
# ═════════════════════════════════════════════════════════════════════════════
# - Compilers (gcc, g++, javac, tsc)
# - Build tools (maven, gradle, webpack, npm)
# - Development headers (libpq-dev, python-dev)
# - Testing frameworks (jest, pytest)
# - Linters and formatters
# - Documentation generators

# ═════════════════════════════════════════════════════════════════════════════
# RUNTIME DEPENDENCIES (in production stage)
# ═════════════════════════════════════════════════════════════════════════════
# - Runtime libraries (libpq5, not libpq-dev)
# - Application runtime (node, python, java)
# - Compiled artifacts (binaries, JARs, bundles)
# - Configuration files
# - Static assets

FROM python:3.11 AS builder
# Build-time: includes gcc, python3-dev for compiling packages
RUN pip install psycopg2  # Requires compilation

FROM python:3.11-slim AS production
# Runtime: only needs libpq5 (runtime library, not headers)
RUN apt-get update && apt-get install -y libpq5
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/
```

#### Best Practices for Multi-Stage Builds

**1. Stage Ordering for Optimal Caching**

```dockerfile
# ✅ GOOD: Order stages from least to most frequently changed
FROM node:18 AS dependencies
# Changes rarely
COPY package.json package-lock.json ./
RUN npm ci

FROM node:18 AS builder  
# Changes occasionally
COPY --from=dependencies /app/node_modules ./node_modules
COPY tsconfig.json ./

# Changes frequently
COPY src/ ./src/
RUN npm run build

# ❌ BAD: Mixing concerns invalidates cache unnecessarily
FROM node:18 AS builder
COPY . .  # Everything! Any file change invalidates cache
RUN npm ci && npm run build
```

**2. Use Specific Stage Names**

```dockerfile
# ✅ GOOD: Descriptive names make Dockerfile self-documenting
FROM node:18 AS dependencies
FROM node:18 AS builder
FROM node:18 AS tester
FROM node:18-alpine AS production

# ❌ BAD: Generic names
FROM node:18 AS stage1
FROM node:18 AS stage2
```

**3. Minimize Layer Count in Final Stage**

```dockerfile
# ✅ GOOD: Few layers in production
FROM alpine:3.18 AS production
COPY --from=builder /app/binary /app/
COPY --from=builder /app/config /config/
# Only 2 layers added

# ❌ BAD: Many unnecessary layers
FROM alpine:3.18 AS production
RUN apk add ca-certificates
RUN mkdir /app
COPY --from=builder /app/binary /app/
RUN chmod +x /app/binary
# 4 layers when 2 would suffice
```

#### When to Use Multi-Stage Builds

**✅ Use Multi-Stage Builds When:**

- Compiling code (Go, Java, TypeScript, C++)
- Building static sites (React, Vue, Angular)
- Application needs build tools not required at runtime
- Creating minimal production images
- Separating test and production environments
- Working with multiple programming languages in one image

**❌ Don't Use Multi-Stage Builds When:**

- Interpreted languages with no build step (simple Python/Ruby scripts)
- Image is already minimal (copying from scratch to scratch)
- Build process is trivial (just copying files)
- Debugging and you need build tools in production (temporarily)

#### Common Pitfalls and Solutions

**Pitfall 1: File Permissions**

```dockerfile
# ❌ PROBLEM: Files copied have root ownership
COPY --from=builder /app/dist ./dist
USER appuser  # Can't write to dist/

# ✅ SOLUTION: Use --chown flag
COPY --from=builder --chown=appuser:appuser /app/dist ./dist
USER appuser
```

**Pitfall 2: Missing Runtime Dependencies**

```dockerfile
# ❌ PROBLEM: Forgot runtime libraries
FROM python:3.11-slim
COPY --from=builder /app/env /app/env
CMD ["python", "app.py"]  # ImportError: libpq.so.5

# ✅ SOLUTION: Install runtime deps
FROM python:3.11-slim
RUN apt-get update && apt-get install -y libpq5
COPY --from=builder /app/env /app/env
```

**Pitfall 3: Unnecessary Files in Final Image**

```dockerfile
# ❌ PROBLEM: Copying too much
COPY --from=builder /app ./app  # Includes tests, docs, temp files

# ✅ SOLUTION: Copy only what's needed
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/config ./config
```

**Pitfall 4: Not Using .dockerignore**

```bash
# ❌ PROBLEM: Copying unnecessary files to builder
# COPY . . copies node_modules, .git, test files

# ✅ SOLUTION: Create .dockerignore
cat > .dockerignore <<EOF
node_modules
.git
*.log
.env
test/
docs/
*.md
EOF
```

#### Debugging Multi-Stage Builds

**1. Build Specific Stage**

```bash
# Build and inspect builder stage
docker build --target builder -t debug:builder .
docker run -it debug:builder sh

# Check what files exist
ls -la /app
```

**2. Use Build Output**

```bash
# See detailed build output
docker build --progress=plain --no-cache .

# See layer sizes
docker history myimage:latest
```

**3. Inspect Stage Artifacts**

```dockerfile
# Add debugging stage
FROM builder AS debug
RUN find /app -type f -exec ls -lh {} \;
RUN du -sh /app/*
```

**4. Override Entrypoint**

```bash
# Run production image with shell instead of app
docker run -it --entrypoint sh myapp:latest

# Check what was copied
ls -la
```

#### Size Comparison Summary

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                IMAGE SIZE REDUCTION WITH MULTI-STAGE BUILDS                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Language/Framework    │  Single-Stage  │  Multi-Stage   │  Reduction              │
│   ──────────────────────┼────────────────┼────────────────┼──────────────────────   │
│   Node.js/TypeScript    │    1,200 MB    │     150 MB     │  88% (8x smaller)       │
│   Python/Flask          │    1,000 MB    │     200 MB     │  80% (5x smaller)       │
│   Go                    │      800 MB    │      10 MB     │  98% (80x smaller!)     │
│   Java/Spring Boot      │      850 MB    │     200 MB     │  76% (4x smaller)       │
│   React/TypeScript      │    1,200 MB    │      40 MB     │  96% (30x smaller!)     │
│                                                                                      │
│   Average Reduction: ~88% smaller                                                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

#### Performance Comparison

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     BUILD TIME WITH CACHING                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   Scenario                      │  First Build  │  Code Change  │  Dep Change       │
│   ──────────────────────────────┼───────────────┼───────────────┼─────────────────  │
│   Single-stage (no caching)     │     120s      │     120s      │     120s          │
│   Single-stage (with caching)   │     120s      │      60s      │     120s          │
│   Multi-stage (with caching)    │     130s      │      15s      │      80s          │
│                                                                                      │
│   Multi-stage is 4x faster for typical code changes!                               │
│   Slightly slower first build, but much faster iteration                           │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Best Practices

**1. Order Instructions for Cache Optimization**

```dockerfile
# ✅ GOOD: Dependencies change less often than code
FROM python:3.11-slim
WORKDIR /app

# Copy only requirements first
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy code (changes frequently)
COPY . .

CMD ["python", "app.py"]
```

```dockerfile
# ❌ BAD: Any code change invalidates pip cache
FROM python:3.11-slim
WORKDIR /app

COPY . .
RUN pip install -r requirements.txt

CMD ["python", "app.py"]
```

**2. Minimize Layers**

```dockerfile
# ✅ GOOD: Single layer for related operations
RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
        vim && \
    rm -rf /var/lib/apt/lists/*

# ❌ BAD: Multiple unnecessary layers
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y vim
```

**3. Use .dockerignore**

```dockerignore
# .dockerignore
.git
.gitignore
node_modules
*.log
*.md
Dockerfile
docker-compose.yml
.env
.vscode
__pycache__
*.pyc
.pytest_cache
coverage/
```

---

## Docker Networking

Docker networking is a powerful subsystem that enables communication between containers, hosts, and external networks. Understanding Docker networking is crucial for building scalable, secure, and performant containerized applications.

### 1. Docker Network Architecture Overview

Docker uses a pluggable networking architecture based on the Container Network Model (CNM). The CNM provides network abstraction and consists of three main components:

- **Sandbox**: Contains network configuration for a container (namespace, routing tables, DNS settings)
- **Endpoint**: Virtual network interface connecting a sandbox to a network
- **Network**: A group of endpoints that can communicate with each other

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Host                          │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │  Container 1 │      │  Container 2 │                   │
│  │              │      │              │                   │
│  │  ┌────────┐  │      │  ┌────────┐  │                   │
│  │  │Sandbox │  │      │  │Sandbox │  │                   │
│  │  │  eth0  │  │      │  │  eth0  │  │                   │
│  │  └───┬────┘  │      │  └───┬────┘  │                   │
│  └──────┼───────┘      └──────┼───────┘                   │
│         │                     │                           │
│    ┌────▼─────────────────────▼────┐                      │
│    │      Docker Bridge (docker0)  │                      │
│    │       Network: 172.17.0.0/16  │                      │
│    └────────────┬──────────────────┘                      │
│                 │                                          │
│            ┌────▼────┐                                     │
│            │  eth0   │  Host Network Interface             │
│            └────┬────┘                                     │
└─────────────────┼──────────────────────────────────────────┘
                  │
                  ▼
            External Network
```

### 2. Bridge Networks - Deep Dive

Bridge networks are the default network driver in Docker. When you start Docker, a default bridge network is created automatically.

#### 2.1 Default Bridge Network

**Architecture**:
```
Host Machine (192.168.1.100)
│
├─── docker0 bridge (172.17.0.1)
│    │
│    ├─── veth-abc123 ←→ Container1 eth0 (172.17.0.2)
│    │
│    └─── veth-def456 ←→ Container2 eth0 (172.17.0.3)
│
└─── eth0 (Physical Interface)
```

**Packet Flow Diagram**:
```
Container A (172.17.0.2) → Container B (172.17.0.3)
│
├─ 1. Packet leaves Container A's eth0
│     Source: 172.17.0.2, Dest: 172.17.0.3
│
├─ 2. Enters veth pair (host side)
│
├─ 3. Reaches docker0 bridge
│     Bridge performs L2 switching
│
├─ 4. Forwarded to Container B's veth pair
│
└─ 5. Arrives at Container B's eth0
```

**Practical Example**:
```bash
# Create two containers on default bridge
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Inspect network details
docker network inspect bridge

# Get container IPs
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web2

# Test connectivity (Note: default bridge doesn't support DNS resolution by name)
docker exec web1 ping -c 3 $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web2)
```

#### 2.2 Custom Bridge Networks (Recommended)

Custom bridge networks provide better isolation and automatic DNS resolution.

```bash
# Create custom bridge network
docker network create --driver bridge my-bridge-network

# Create with specific subnet and gateway
docker network create \
  --driver bridge \
  --subnet=192.168.100.0/24 \
  --gateway=192.168.100.1 \
  --ip-range=192.168.100.128/25 \
  custom-net

# Run containers on custom network
docker run -d --name app1 --network my-bridge-network nginx
docker run -d --name app2 --network my-bridge-network nginx

# Test DNS resolution (works on custom networks!)
docker exec app1 ping -c 3 app2
docker exec app2 curl http://app1
```

**Custom Bridge Network Architecture**:
```
┌─────────────────────────────────────────────────────┐
│ Custom Bridge Network (my-bridge-network)           │
│ Subnet: 192.168.100.0/24                           │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │  app1            │      │  app2            │   │
│  │  192.168.100.2   │◄────►│  192.168.100.3   │   │
│  │                  │ DNS  │                  │   │
│  └──────────────────┘      └──────────────────┘   │
│                                                     │
│  Embedded DNS Server: 127.0.0.11                   │
│  DNS Resolution: app1 → 192.168.100.2              │
└─────────────────────────────────────────────────────┘
```

### 3. Container-to-Container Communication

#### 3.1 Same Network Communication

```bash
# Create a custom network
docker network create app-network

# Run database container
docker run -d \
  --name postgres-db \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:14

# Run application container
docker run -d \
  --name web-app \
  --network app-network \
  -e DATABASE_URL=postgresql://postgres:secret@postgres-db:5432/mydb \
  myapp:latest

# The web-app can reach postgres-db using the container name as hostname
```

#### 3.2 Multi-Network Communication

Containers can be connected to multiple networks:

```bash
# Create frontend and backend networks
docker network create frontend
docker network create backend

# Run database on backend only
docker run -d --name db --network backend postgres:14

# Run API server on both networks
docker run -d --name api \
  --network backend \
  myapi:latest

docker network connect frontend api

# Run web server on frontend only
docker run -d --name web --network frontend nginx

# Result:
# - web can communicate with api (both on frontend)
# - api can communicate with db (both on backend)
# - web CANNOT communicate with db (network isolation)
```

**Multi-Network Architecture**:
```
┌──────────────────────────────────────────────────────┐
│                    Docker Host                       │
│                                                      │
│  ┌────────────────────┐  ┌────────────────────┐    │
│  │  Frontend Network  │  │  Backend Network   │    │
│  │                    │  │                    │    │
│  │  ┌─────┐           │  │           ┌─────┐ │    │
│  │  │ Web │           │  │           │ DB  │ │    │
│  │  └──┬──┘           │  │           └──┬──┘ │    │
│  │     │              │  │              │    │    │
│  │     │  ┌────────┐  │  │  ┌────────┐ │    │    │
│  │     └──┤  API   ├──┼──┼──┤  API   ├─┘    │    │
│  │        │(eth0)  │  │  │  │(eth1)  │      │    │
│  │        └────────┘  │  │  └────────┘      │    │
│  └────────────────────┘  └────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

### 4. Port Mapping Deep Dive

Port mapping allows external access to containerized services using Docker's port forwarding mechanism.

#### 4.1 Port Mapping Mechanisms

When you publish a port, Docker creates iptables rules to forward traffic:

```bash
# Publish port 8080 on host to port 80 in container
docker run -d -p 8080:80 --name web nginx

# View the iptables rules Docker created
sudo iptables -t nat -L -n | grep 8080
```

**iptables Rules Created**:
```
Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  tcp  --  172.17.0.2           172.17.0.2           tcp dpt:80
```

#### 4.2 Port Mapping Flow Diagram

```
External Client (192.168.1.50:54321)
│
├─ Request: 192.168.1.100:8080
│
▼
┌──────────────────────────────────────────┐
│ Host eth0 (192.168.1.100)                │
│                                          │
│ iptables PREROUTING                      │
│ DNAT: :8080 → 172.17.0.2:80             │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ docker0 bridge (172.17.0.1)              │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Container (172.17.0.2:80)                │
│ nginx listening on port 80               │
└──────────────────────────────────────────┘

Response follows reverse path with SNAT
```

#### 4.3 Port Mapping Examples

```bash
# Map specific port
docker run -d -p 8080:80 nginx

# Map to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx  # Only localhost

# Map random host port
docker run -d -p 80 nginx  # Docker assigns random port

# Map UDP ports
docker run -d -p 53:53/udp dns-server

# Map multiple ports
docker run -d -p 80:80 -p 443:443 nginx

# Map range of ports
docker run -d -p 8000-8010:8000-8010 myapp

# Publish all exposed ports to random ports
docker run -d -P nginx
```

### 5. Host Network Mode

In host mode, containers share the host's network namespace directly - no network isolation.

#### 5.1 Host Network Architecture

```
┌───────────────────────────────────────────┐
│           Docker Host                     │
│                                           │
│  ┌─────────────────────────────────┐     │
│  │  Container (host network)       │     │
│  │  No separate namespace          │     │
│  │  Direct access to host network  │     │
│  └─────────────────────────────────┘     │
│                  │                        │
│                  │ (shares)               │
│                  ▼                        │
│         ┌────────────────┐                │
│         │  Host Network  │                │
│         │  Namespace     │                │
│         │  eth0, lo, etc │                │
│         └────────────────┘                │
└───────────────────────────────────────────┘
```

#### 5.2 Host Network Examples

```bash
# Run container with host network
docker run -d --network host nginx

# No port mapping needed - container binds directly to host ports
# nginx listens on host's port 80 directly

# Performance test example
docker run -it --rm --network host nicolaka/netshoot iperf3 -s
```

#### 5.3 Performance Comparison

**Benchmark Results** (Typical):
```
Network Mode    | Throughput  | Latency  | Use Case
----------------|-------------|----------|------------------
Bridge          | ~10 Gbps    | ~0.1ms   | Default, isolated
Host            | ~40 Gbps    | ~0.01ms  | High-performance
Overlay         | ~8 Gbps     | ~0.2ms   | Multi-host
```

**When to Use Host Network**:
- High-performance networking requirements
- Need to bind to all host interfaces
- Running network monitoring tools
- Testing/development scenarios

**Limitations**:
- No network isolation
- Port conflicts with host services
- Doesn't work on Docker Desktop (Mac/Windows)
- Reduces container portability

### 6. None Network Mode

The `none` network provides complete network isolation - no network interfaces except loopback.

```bash
# Create container with no network
docker run -d --network none --name isolated alpine sleep 3600

# Verify no network interfaces (except lo)
docker exec isolated ip addr show
# Output shows only:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
```

**Use Cases**:
- Maximum security isolation
- Batch processing jobs with no network needs
- Protecting sensitive data processing
- Testing applications in isolation

**Architecture**:
```
┌─────────────────────────┐
│  Container (none)       │
│                         │
│  ┌──────────────────┐   │
│  │  Network Stack   │   │
│  │  lo: 127.0.0.1   │   │
│  │  (loopback only) │   │
│  └──────────────────┘   │
│                         │
│  No external network    │
└─────────────────────────┘
```

### 7. Network Namespaces Explained

Network namespaces provide network isolation by giving each container its own network stack.

#### 7.1 Namespace Components

Each network namespace includes:
- Network devices (virtual interfaces)
- IP addresses and routing tables
- Firewall rules (iptables/nftables)
- Network statistics
- Port numbers

#### 7.2 Exploring Network Namespaces

```bash
# List all network namespaces
sudo ls -la /var/run/docker/netns/

# Run a container
docker run -d --name test nginx

# Find the container's network namespace
container_pid=$(docker inspect -f '{{.State.Pid}}' test)
echo $container_pid

# Enter the container's network namespace using nsenter
sudo nsenter -t $container_pid -n ip addr show

# Or use docker exec
docker exec test ip addr show

# View routing table inside container
docker exec test ip route show

# View iptables rules
docker exec test iptables -L -n
```

#### 7.3 Virtual Ethernet (veth) Pairs

```bash
# Create container
docker run -d --name web nginx

# Find veth pair on host
container_if=$(docker exec web cat /sys/class/net/eth0/iflink)
ip link | grep "^${container_if}:"

# This shows the host-side veth interface connected to the container
```

**veth Pair Visualization**:
```
┌─────────────────────────────────────────────────────────┐
│                     Docker Host                         │
│                                                         │
│  Container Namespace          Host Namespace           │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │  eth0@if8        │◄──────►│  veth1a2b3c4@if7 │     │
│  │  172.17.0.2      │        │  (no IP)         │     │
│  └──────────────────┘        └────────┬─────────┘     │
│                                        │               │
│                              ┌─────────▼─────────┐     │
│                              │   docker0 bridge  │     │
│                              │   172.17.0.1      │     │
│                              └───────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### 8. Overlay Networks for Swarm/Multi-Host

Overlay networks enable container communication across multiple Docker hosts.

#### 8.1 Overlay Network Architecture

```
┌─────────────────────┐          ┌─────────────────────┐
│   Docker Host 1     │          │   Docker Host 2     │
│   192.168.1.10      │          │   192.168.1.20      │
│                     │          │                     │
│  ┌──────────────┐   │          │   ┌──────────────┐ │
│  │ Container A  │   │          │   │ Container B  │ │
│  │ 10.0.0.2     │   │          │   │ 10.0.0.3     │ │
│  └──────┬───────┘   │          │   └──────┬───────┘ │
│         │           │          │          │         │
│    ┌────▼──────┐    │          │    ┌─────▼─────┐   │
│    │  Overlay  │    │          │    │  Overlay  │   │
│    │  Network  │    │          │    │  Network  │   │
│    │ 10.0.0.0/24│   │          │    │ 10.0.0.0/24│  │
│    └────┬───────┘   │          │    └─────┬──────┘  │
│         │ VXLAN     │          │          │ VXLAN   │
│    ┌────▼───────┐   │          │    ┌─────▼──────┐  │
│    │   eth0     ├───┼──────────┼────┤   eth0     │  │
│    └────────────┘   │   VXLAN  │    └────────────┘  │
│                     │  Tunnel  │                     │
└─────────────────────┘          └─────────────────────┘
```

#### 8.2 Creating Overlay Networks

```bash
# Initialize Swarm (required for overlay networks)
docker swarm init

# Create overlay network
docker network create \
  --driver overlay \
  --subnet 10.0.0.0/24 \
  --gateway 10.0.0.1 \
  my-overlay

# Create attachable overlay (for standalone containers)
docker network create \
  --driver overlay \
  --attachable \
  app-overlay

# Deploy service using overlay network
docker service create \
  --name web \
  --network my-overlay \
  --replicas 3 \
  nginx

# Containers across hosts can communicate via service name
```

#### 8.3 Overlay Network Features

**Encapsulation**:
- Uses VXLAN (Virtual Extensible LAN)
- UDP port 4789 for VXLAN traffic
- Encrypted option available

```bash
# Create encrypted overlay network
docker network create \
  --driver overlay \
  --opt encrypted \
  secure-overlay
```

**Packet Flow in Overlay**:
```
Container A (Host 1) → Container B (Host 2)

1. Packet created: src=10.0.0.2, dst=10.0.0.3
2. VXLAN encapsulation adds outer header
   Outer: src=192.168.1.10, dst=192.168.1.20
   Inner: src=10.0.0.2, dst=10.0.0.3
3. Packet sent over physical network
4. Host 2 receives, de-encapsulates VXLAN
5. Inner packet delivered to Container B
```

### 9. Macvlan Networks for Direct Network Access

Macvlan allows containers to appear as physical devices on the network with their own MAC addresses.

#### 9.1 Macvlan Architecture

```
┌─────────────────────────────────────────────────────┐
│              Physical Network (192.168.1.0/24)      │
│                                                     │
│  Router: 192.168.1.1                                │
│     │                                               │
│     ├── Host: 192.168.1.100                         │
│     ├── Container1: 192.168.1.101 (MAC: aa:bb:..)   │
│     └── Container2: 192.168.1.102 (MAC: cc:dd:..)   │
└─────────────────────────────────────────────────────┘

Docker Host (192.168.1.100)
│
├─── eth0 (Physical Interface)
│    │
│    ├─── eth0.10 (macvlan sub-interface)
│         │
│         ├─── Container1 (192.168.1.101)
│         └─── Container2 (192.168.1.102)
```

#### 9.2 Creating Macvlan Networks

```bash
# Create macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan-net

# Run container with macvlan
docker run -d \
  --network macvlan-net \
  --ip=192.168.1.101 \
  --name container1 \
  nginx

# Container appears as a separate device on the network
# Can be accessed directly at 192.168.1.101
```

#### 9.3 Macvlan Modes

**Bridge Mode** (default):
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  -o macvlan_mode=bridge \
  macvlan-bridge
```

**802.1Q VLAN Trunk**:
```bash
# Create macvlan on VLAN 10
docker network create -d macvlan \
  --subnet=10.10.10.0/24 \
  --gateway=10.10.10.1 \
  -o parent=eth0.10 \
  macvlan-vlan10

# Create macvlan on VLAN 20
docker network create -d macvlan \
  --subnet=10.10.20.0/24 \
  --gateway=10.10.20.1 \
  -o parent=eth0.20 \
  macvlan-vlan20
```

**Use Cases**:
- Legacy applications requiring direct network access
- Network monitoring tools
- DHCP servers
- Applications needing specific MAC addresses

**Limitations**:
- Requires promiscuous mode on NIC
- May not work in cloud environments
- Host cannot communicate with containers by default

### 10. Network Troubleshooting Techniques

#### 10.1 Essential Troubleshooting Commands

```bash
# Inspect network details
docker network inspect bridge
docker network inspect <network-name>

# View container network settings
docker inspect <container-name> | jq '.[0].NetworkSettings'

# List all networks
docker network ls

# Check container connectivity
docker exec <container> ping -c 3 <target>
docker exec <container> curl -v <url>
docker exec <container> wget -O- <url>

# DNS resolution testing
docker exec <container> nslookup <hostname>
docker exec <container> dig <hostname>
docker exec <container> cat /etc/resolv.conf

# View network interfaces in container
docker exec <container> ip addr show
docker exec <container> ifconfig

# Check routing table
docker exec <container> ip route show
docker exec <container> route -n

# Port listening verification
docker exec <container> netstat -tlnp
docker exec <container> ss -tlnp

# Test port connectivity
docker exec <container> telnet <host> <port>
docker exec <container> nc -zv <host> <port>
```

#### 10.2 Advanced Debugging with netshoot

```bash
# Run netshoot container with network debugging tools
docker run -it --rm --network container:<target-container> nicolaka/netshoot

# Inside netshoot, you have access to:
# - tcpdump, wireshark (tshark)
# - nmap, ncat, socat
# - curl, wget, httpie
# - dig, nslookup, drill
# - iperf3, ab (apache bench)
# - and many more...

# Capture packets
tcpdump -i eth0 -w /tmp/capture.pcap

# Scan ports
nmap -sT localhost

# HTTP performance testing
ab -n 1000 -c 10 http://web/

# Network performance
iperf3 -c <server-ip>
```

#### 10.3 Analyzing iptables Rules

```bash
# View all iptables rules Docker created
sudo iptables -t nat -L -n -v
sudo iptables -t filter -L -n -v

# View Docker-specific chains
sudo iptables -t nat -L DOCKER -n -v
sudo iptables -t filter -L DOCKER -n -v

# Trace packet flow
sudo iptables -t raw -A PREROUTING -p tcp --dport 8080 -j TRACE
sudo iptables -t raw -A OUTPUT -p tcp --sport 8080 -j TRACE

# View trace in logs
sudo tail -f /var/log/kern.log | grep TRACE
```

#### 10.4 Common Issues and Solutions

**Issue 1: Container Cannot Resolve DNS**
```bash
# Check DNS configuration
docker exec <container> cat /etc/resolv.conf

# Solution: Specify DNS servers
docker run --dns 8.8.8.8 --dns 8.8.4.4 <image>

# Or configure daemon-wide
# /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

**Issue 2: Containers on Default Bridge Cannot Communicate by Name**
```bash
# Problem: Default bridge doesn't support automatic DNS
# Solution: Use custom bridge network
docker network create my-network
docker run --network my-network --name app1 <image>
docker run --network my-network --name app2 <image>
# Now app1 and app2 can resolve each other by name
```

**Issue 3: Port Already in Use**
```bash
# Check what's using the port
sudo lsof -i :<port>
sudo netstat -tlnp | grep <port>

# Solution: Use different host port or stop conflicting service
docker run -p 8081:80 nginx  # Instead of 8080:80
```

**Issue 4: Cannot Access Published Ports**
```bash
# Check if port is actually published
docker port <container>

# Check if firewall is blocking
sudo iptables -L -n | grep <port>
sudo ufw status

# Check if binding to correct interface
docker run -p 0.0.0.0:8080:80 nginx  # All interfaces
docker run -p 127.0.0.1:8080:80 nginx  # Localhost only
```

### 11. Real-World Multi-Tier Application Network Architecture

Let's design a complete production-grade application network architecture.

#### 11.1 Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Host                          │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Public Network (frontend)             │    │
│  │                                                     │    │
│  │  ┌──────────────┐         ┌──────────────┐        │    │
│  │  │   Nginx      │         │   Nginx      │        │    │
│  │  │   Proxy      │         │   Proxy      │        │    │
│  │  │   (LB)       │         │   (backup)   │        │    │
│  │  └──────┬───────┘         └──────────────┘        │    │
│  │         │                                          │    │
│  └─────────┼──────────────────────────────────────────┘    │
│            │                                               │
│  ┌─────────▼──────────────────────────────────────────┐    │
│  │           Application Network (backend)            │    │
│  │                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │    │
│  │  │  API     │  │  API     │  │  API     │        │    │
│  │  │  App 1   │  │  App 2   │  │  App 3   │        │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘        │    │
│  │       │             │             │               │    │
│  └───────┼─────────────┼─────────────┼───────────────┘    │
│          │             │             │                    │
│  ┌───────▼─────────────▼─────────────▼───────────────┐    │
│  │            Database Network (private)             │    │
│  │                                                    │    │
│  │  ┌──────────┐         ┌──────────┐               │    │
│  │  │ PostgreSQL│         │  Redis  │               │    │
│  │  │  Primary │         │  Cache  │               │    │
│  │  └──────────┘         └──────────┘               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Monitoring Network (isolated)              │    │
│  │                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │    │
│  │  │Prometheus│  │ Grafana  │  │ Alertmgr │        │    │
│  │  └──────────┘  └──────────┘  └──────────┘        │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

#### 11.2 Implementation with Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  
  backend:
    driver: bridge
    internal: false
    ipam:
      config:
        - subnet: 172.21.0.0/24
  
  database:
    driver: bridge
    internal: true  # No external access
    ipam:
      config:
        - subnet: 172.22.0.0/24
  
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/24

services:
  # Load Balancer / Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    networks:
      - frontend
      - backend
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api-1
      - api-2
      - api-3
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  # API Application Instances
  api-1:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  api-2:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379

  api-3:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379

  # Database
  db:
    image: postgres:14
    networks:
      - database
      - monitoring
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=appdb
    volumes:
      - db-data:/var/lib/postgresql/data
    deploy:
      placement:
        constraints:
          - node.role == manager

  # Cache
  cache:
    image: redis:7-alpine
    networks:
      - database
      - monitoring
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    networks:
      - monitoring
      - backend
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    networks:
      - monitoring
      - frontend
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  db-data:
  redis-data:
  prometheus-data:
  grafana-data:
```

#### 11.3 Manual Setup Commands

```bash
# Create networks
docker network create --subnet=172.20.0.0/24 frontend
docker network create --subnet=172.21.0.0/24 backend
docker network create --subnet=172.22.0.0/24 --internal database
docker network create --subnet=172.23.0.0/24 monitoring

# Database layer
docker run -d \
  --name postgres \
  --network database \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:14

docker run -d \
  --name redis \
  --network database \
  redis:7-alpine

# Connect database to monitoring
docker network connect monitoring postgres
docker network connect monitoring redis

# Application layer
for i in 1 2 3; do
  docker run -d \
    --name api-$i \
    --network backend \
    -e DATABASE_URL=postgresql://postgres:secret@postgres:5432/db \
    -e REDIS_URL=redis://redis:6379 \
    myapi:latest
  
  docker network connect database api-$i
done

# Frontend layer
docker run -d \
  --name nginx \
  --network frontend \
  -p 80:80 -p 443:443 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

docker network connect backend nginx

# Monitoring
docker run -d \
  --name prometheus \
  --network monitoring \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus

docker network connect backend prometheus

docker run -d \
  --name grafana \
  --network monitoring \
  -p 3000:3000 \
  grafana/grafana

docker network connect frontend grafana
```

### 12. Security Considerations and Network Isolation

#### 12.1 Network Isolation Best Practices

**Principle of Least Privilege**:
```bash
# Create isolated networks for different tiers
docker network create --internal db-network
docker network create --internal cache-network
docker network create app-network

# Only expose what's necessary
# Database: Only on db-network
docker run -d --name db --network db-network postgres

# App: On both app and db networks
docker run -d --name api --network app-network myapi
docker network connect db-network api

# Proxy: Only on app network, published ports
docker run -d --name proxy --network app-network -p 80:80 nginx
```

#### 12.2 Internal Networks

Internal networks prevent external access completely:

```bash
# Create internal network (no gateway, no external access)
docker network create --internal secure-network

# Containers can communicate with each other but not external world
docker run -d --name db --network secure-network postgres
docker run -d --name app --network secure-network myapp

# App cannot reach internet, only db
```

#### 12.3 Network Policies and Firewall Rules

```bash
# Custom iptables rules for additional security
# Block inter-container communication except on specific ports

# Allow only port 5432 between app and db
sudo iptables -I DOCKER-USER -s 172.18.0.0/24 -d 172.19.0.2 -p tcp --dport 5432 -j ACCEPT
sudo iptables -I DOCKER-USER -s 172.18.0.0/24 -d 172.19.0.0/24 -j DROP

# Rate limiting
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m state --state NEW -m recent --set
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 -j DROP
```

#### 12.4 Encrypted Networks

```bash
# Create encrypted overlay network (Swarm mode)
docker network create \
  --driver overlay \
  --opt encrypted \
  --attachable \
  secure-overlay

# All traffic between nodes is encrypted via IPSec
```

#### 12.5 Security Scanning and Monitoring

```bash
# Monitor network traffic
docker run -d \
  --name network-monitor \
  --network host \
  --cap-add NET_ADMIN \
  nicolaka/netshoot tcpdump -i any -w /captures/traffic.pcap

# Use Docker Bench Security
docker run -it --net host --pid host --userns host --cap-add audit_control \
  -v /etc:/etc:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security

# Check for exposed services
nmap -sV -p- <docker-host-ip>
```

#### 12.6 Security Checklist

```
✓ Use custom bridge networks instead of default bridge
✓ Enable ICC (Inter-Container Communication) only when needed
✓ Use internal networks for databases and sensitive services
✓ Implement network segmentation (multi-tier architecture)
✓ Encrypt overlay networks in production
✓ Use TLS/SSL for all external communications
✓ Limit published ports to minimum required
✓ Bind ports to specific interfaces (127.0.0.1 for local only)
✓ Regularly audit network configurations
✓ Use secrets management for sensitive data
✓ Monitor network traffic for anomalies
✓ Keep Docker and kernels updated
✓ Use user namespaces when possible
✓ Implement rate limiting and DDoS protection
✓ Regular security scanning of images and containers
```

### 13. Performance Tuning for Networks

#### 13.1 Network Driver Selection

**Performance Characteristics**:
```
Driver      | Overhead | Isolation | Multi-Host | Use Case
------------|----------|-----------|------------|------------------
host        | Minimal  | None      | No         | Max performance
bridge      | Low      | Good      | No         | Default choice
macvlan     | Low      | Medium    | No         | Direct access
overlay     | Medium   | Good      | Yes        | Swarm/multi-host
```

#### 13.2 Kernel Parameters Tuning

```bash
# /etc/sysctl.conf optimizations for Docker networking

# Increase connection tracking
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 600

# TCP tuning
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535

# Buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 87380 134217728

# Optimize for high throughput
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# Apply changes
sudo sysctl -p
```

#### 13.3 Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ],
  "mtu": 1500,
  "live-restore": true,
  "userland-proxy": false,  // Use hairpin NAT instead (better performance)
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "ipv6": false,
  "fixed-cidr-v6": "",
  "bridge": "docker0",
  "default-gateway": "",
  "dns": ["8.8.8.8", "8.8.4.4"],
  "dns-opts": [],
  "dns-search": [],
  "bip": "172.17.0.1/16"
}
```

#### 13.4 MTU Optimization

```bash
# Check current MTU
docker network inspect bridge | grep com.docker.network.driver.mtu

# Create network with custom MTU (jumbo frames for 10GbE)
docker network create \
  --opt com.docker.network.driver.mtu=9000 \
  high-perf-network

# For overlay networks in Swarm
docker network create \
  --driver overlay \
  --opt com.docker.network.driver.mtu=1450 \
  overlay-net
```

#### 13.5 Performance Benchmarking

```bash
# Network throughput test
# Server container
docker run -it --rm --network host nicolaka/netshoot iperf3 -s

# Client container
docker run -it --rm --network host nicolaka/netshoot iperf3 -c <server-ip> -t 30

# Latency test
docker run -it --rm --network host nicolaka/netshoot ping -c 100 <target>

# HTTP performance
docker run -it --rm --network host nicolaka/netshoot \
  ab -n 10000 -c 100 http://<target>/

# Compare bridge vs host performance
echo "Bridge network:"
docker run --rm --network bridge nicolaka/netshoot iperf3 -c <server> -t 10

echo "Host network:"
docker run --rm --network host nicolaka/netshoot iperf3 -c <server> -t 10
```

#### 13.6 Monitoring Network Performance

```bash
# Install cAdvisor for container metrics
docker run -d \
  --name=cadvisor \
  --network=monitoring \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  google/cadvisor:latest

# Network statistics per container
docker stats --format "table {{.Container}}\t{{.NetIO}}"

# Detailed network metrics
docker inspect <container> | jq '.[0].NetworkSettings.Networks'
```

### 14. Debugging Network Issues with Practical Commands

#### 14.1 Connectivity Troubleshooting Workflow

```bash
# Step 1: Verify container is running
docker ps | grep <container-name>
docker inspect <container-name> | jq '.[0].State'

# Step 2: Check network connectivity
docker exec <container> ip addr show
docker exec <container> ip route show

# Step 3: Test DNS resolution
docker exec <container> nslookup <hostname>
docker exec <container> cat /etc/resolv.conf

# Step 4: Test connectivity to specific service
docker exec <container> ping -c 3 <target>
docker exec <container> telnet <host> <port>
docker exec <container> curl -v http://<service>

# Step 5: Check listening ports
docker exec <container> netstat -tlnp
docker exec <container> ss -tlnp

# Step 6: Verify iptables rules
sudo iptables -t nat -L -n -v | grep <container-ip>

# Step 7: Check Docker network configuration
docker network inspect <network-name>
```

#### 14.2 Packet Capture and Analysis

```bash
# Capture traffic on docker0 bridge
sudo tcpdump -i docker0 -w /tmp/docker-traffic.pcap

# Capture traffic for specific container
container_pid=$(docker inspect -f '{{.State.Pid}}' <container>)
sudo nsenter -t $container_pid -n tcpdump -i eth0 -w /tmp/container-traffic.pcap

# Capture with filters
sudo tcpdump -i docker0 'port 80 or port 443' -w /tmp/http-traffic.pcap

# Analyze with tshark
tshark -r /tmp/docker-traffic.pcap -Y "http.request"

# Real-time analysis
docker run -it --rm --net container:<target> nicolaka/netshoot
# Inside netshoot:
tcpdump -i eth0 -n -A 'port 80'
```

#### 14.3 DNS Debugging

```bash
# Check DNS configuration
docker exec <container> cat /etc/resolv.conf

# Test DNS resolution
docker exec <container> nslookup google.com
docker exec <container> dig google.com
docker exec <container> host google.com

# Test Docker embedded DNS
docker exec <container> nslookup <container-name>
docker exec <container> dig <container-name> @127.0.0.11

# Override DNS for testing
docker run --dns 8.8.8.8 --dns-search example.com <image>

# Check if DNS is working from host
docker run --rm alpine nslookup google.com
```

#### 14.4 Port Mapping Debugging

```bash
# List port mappings
docker port <container>

# Check if port is listening inside container
docker exec <container> netstat -tlnp | grep <port>

# Check if host port is listening
sudo netstat -tlnp | grep <host-port>
sudo lsof -i :<host-port>

# Test port from outside
telnet <docker-host-ip> <port>
nc -zv <docker-host-ip> <port>
curl -v http://<docker-host-ip>:<port>

# Check iptables NAT rules
sudo iptables -t nat -L DOCKER -n -v
sudo iptables -t nat -L POSTROUTING -n -v

# Trace packets
sudo iptables -t raw -A PREROUTING -p tcp --dport <port> -j TRACE
sudo iptables -t raw -A OUTPUT -p tcp --sport <port> -j TRACE
```

#### 14.5 Inter-Container Communication Testing

```bash
# From container1 to container2
docker exec container1 ping -c 3 container2
docker exec container1 curl http://container2:port
docker exec container1 nc -zv container2 port

# Check if containers are on same network
docker inspect container1 | jq '.[0].NetworkSettings.Networks'
docker inspect container2 | jq '.[0].NetworkSettings.Networks'

# Test with netshoot
docker run -it --rm --network <network-name> nicolaka/netshoot
# From netshoot:
ping container1
nmap -p- container1
curl http://container2
```

#### 14.6 Advanced Debugging Scenarios

**Scenario 1: Container can't reach external services**
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Enable if needed
sudo sysctl net.ipv4.ip_forward=1

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v

# Check if DNS is working
docker exec <container> ping 8.8.8.8  # Test IP
docker exec <container> ping google.com  # Test DNS

# Check routing
docker exec <container> ip route show
docker exec <container> traceroute google.com
```

**Scenario 2: Published port not accessible**
```bash
# Verify port is published
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check firewall
sudo ufw status
sudo iptables -L -n | grep <port>

# Check if bound to correct interface
docker inspect <container> | jq '.[0].NetworkSettings.Ports'

# Test locally first
curl http://localhost:<port>

# Then test from host IP
curl http://$(hostname -I | awk '{print $1}'):<port>

# Check for port conflicts
sudo lsof -i :<port>
```

**Scenario 3: Slow network performance**
```bash
# Check for packet loss
docker exec <container> ping -c 100 <target> | grep loss

# MTU issues
docker exec <container> ping -M do -s 1472 <target>

# Check network stats
docker stats <container>

# Inspect for errors
ip -s link show docker0

# Test bandwidth
docker run --rm --network host nicolaka/netshoot iperf3 -c <server>
```

**Scenario 4: Overlay network issues**
```bash
# Check Swarm status
docker node ls
docker network ls --filter driver=overlay

# Verify encryption
docker network inspect <overlay-network> | jq '.[0].Options'

# Check VXLAN connectivity (port 4789)
sudo tcpdump -i <interface> udp port 4789

# Test cross-node connectivity
docker service create --name test --network <overlay> --replicas 2 alpine sleep 3600
docker exec $(docker ps -q --filter label=com.docker.swarm.service.name=test -n 1) \
  ping <other-replica-ip>
```

#### 14.7 Useful Network Debugging One-Liners

```bash
# Show all container IPs
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)

# Show all containers on a specific network
docker network inspect -f '{{range .Containers}}{{.Name}} {{.IPv4Address}} {{end}}' <network-name>

# Find which network a container is on
docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}' <container>

# Get container's MAC address
docker inspect -f '{{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}}' <container>

# Show all port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}" | column -t

# Get gateway for a container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' <container>

# Check if userland-proxy is running
ps aux | grep docker-proxy

# Monitor connection tracking
watch -n1 'sudo conntrack -L | wc -l'

# Show Docker network drivers
docker network ls --format "{{.Driver}}" | sort | uniq -c
```

---


## Storage and Volumes

### Storage Types

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DOCKER STORAGE TYPES                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   1. VOLUMES (Managed by Docker - Recommended)                                       │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │  Created and managed by Docker                               │                   │
│   │  Stored in /var/lib/docker/volumes/                         │                   │
│   │  Best for: persistent data, sharing between containers      │                   │
│   │                                                              │                   │
│   │  docker volume create mydata                                 │                   │
│   │  docker run -v mydata:/app/data nginx                        │                   │
│   └─────────────────────────────────────────────────────────────┘                   │
│                                                                                      │
│   2. BIND MOUNTS (Direct host path)                                                 │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │  Maps host directory directly to container                  │                   │
│   │  Changes visible immediately (both directions)             │                   │
│   │  Best for: development, config files                        │                   │
│   │                                                              │                   │
│   │  docker run -v /home/user/code:/app nginx                    │                   │
│   │  docker run -v $(pwd):/app nginx                             │                   │
│   └─────────────────────────────────────────────────────────────┘                   │
│                                                                                      │
│   3. TMPFS MOUNTS (In memory only)                                                  │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │  Stored in host's memory, never written to disk            │                   │
│   │  Disappears when container stops                            │                   │
│   │  Best for: sensitive data, temporary files                  │                   │
│   │                                                              │                   │
│   │  docker run --tmpfs /app/temp nginx                          │                   │
│   └─────────────────────────────────────────────────────────────┘                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Volume Commands

```bash
# Create a volume
docker volume create mydata

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Use volume in container
docker run -v mydata:/app/data myapp

# Read-only mount
docker run -v mydata:/app/data:ro myapp

# Remove volume
docker volume rm mydata

# Remove unused volumes
docker volume prune
```

### When to Use What

| Scenario | Storage Type | Why |
|----------|--------------|-----|
| Database data | Volume | Persists, managed by Docker |
| Development code | Bind mount | See changes immediately |
| Config files | Bind mount | Easy to edit from host |
| Secrets/temp data | tmpfs | Never touches disk |
| Sharing between containers | Volume | Both can access |

---

## Docker Compose

### What is Docker Compose?

Docker Compose lets you define and run multi-container applications. Instead of running multiple `docker run` commands, you define everything in a YAML file.

### Basic Structure

```yaml
# docker-compose.yml

# Version is now optional (latest features)
# version: "3.8"

services:
  # Service definitions
  web:
    image: nginx:1.25
    ports:
      - "8080:80"
  
  api:
    build: ./api
    environment:
      - DATABASE_URL=postgres://db:5432/app
  
  db:
    image: postgres:15
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:

networks:
  default:
    driver: bridge
```

### Complete Example with Explanations

```yaml
# docker-compose.yml
# Complete application stack example

services:
  # ─────────────────────────────────────────────────────────────────────
  # Frontend - React application served by nginx
  # ─────────────────────────────────────────────────────────────────────
  frontend:
    build:
      context: ./frontend           # Build context directory
      dockerfile: Dockerfile        # Dockerfile to use
      args:
        - REACT_APP_API_URL=http://api:3000
    image: myapp-frontend:latest    # Tag built image
    ports:
      - "80:80"                     # Host:Container
    depends_on:
      - api                         # Wait for api to start
    restart: unless-stopped         # Restart policy
    networks:
      - frontend-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ─────────────────────────────────────────────────────────────────────
  # API - Node.js backend
  # ─────────────────────────────────────────────────────────────────────
  api:
    build: ./api
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://postgres:${DB_PASSWORD}@db:5432/app
      REDIS_URL: redis://cache:6379
      JWT_SECRET: ${JWT_SECRET}     # From .env file
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy  # Wait for db health check
      cache:
        condition: service_started
    volumes:
      - ./api/logs:/app/logs        # Bind mount for logs
      - uploads:/app/uploads        # Named volume for uploads
    networks:
      - frontend-network
      - backend-network
    deploy:                         # Resource limits
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  # ─────────────────────────────────────────────────────────────────────
  # Database - PostgreSQL
  # ─────────────────────────────────────────────────────────────────────
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"                 # Exposed for debugging
    networks:
      - backend-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ─────────────────────────────────────────────────────────────────────
  # Cache - Redis
  # ─────────────────────────────────────────────────────────────────────
  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend-network

  # ─────────────────────────────────────────────────────────────────────
  # Worker - Background job processor
  # ─────────────────────────────────────────────────────────────────────
  worker:
    build: ./api
    command: npm run worker         # Override default command
    environment:
      DATABASE_URL: postgres://postgres:${DB_PASSWORD}@db:5432/app
      REDIS_URL: redis://cache:6379
    depends_on:
      - db
      - cache
    networks:
      - backend-network
    deploy:
      replicas: 2                   # Run 2 instances

# ─────────────────────────────────────────────────────────────────────
# Named volumes - persistent data
# ─────────────────────────────────────────────────────────────────────
volumes:
  postgres-data:
  redis-data:
  uploads:

# ─────────────────────────────────────────────────────────────────────
# Custom networks - isolation
# ─────────────────────────────────────────────────────────────────────
networks:
  frontend-network:
  backend-network:
```

### Compose Commands

```bash
# Start all services (detached)
docker compose up -d

# Start with build
docker compose up -d --build

# Stop all services
docker compose down

# Stop and remove volumes (careful!)
docker compose down -v

# View logs
docker compose logs
docker compose logs -f api        # Follow specific service

# List running services
docker compose ps

# Execute command in service
docker compose exec api sh

# Scale a service
docker compose up -d --scale worker=5

# Pull latest images
docker compose pull

# Validate compose file
docker compose config
```

---

## Security Best Practices

### Image Security

```dockerfile
# 1. Use specific image tags
FROM python:3.11.4-slim-bookworm   # ✅ Specific
FROM python:latest                   # ❌ Unpredictable

# 2. Use minimal base images
FROM python:3.11-alpine             # ~50MB
FROM python:3.11                    # ~900MB

# 3. Run as non-root user
RUN useradd --create-home appuser
USER appuser

# 4. Don't store secrets in images
# Use environment variables or secret management
ENV API_KEY=xxx                     # ❌ Never!
```

### Runtime Security

```bash
# Read-only root filesystem
docker run --read-only myapp

# Drop all capabilities
docker run --cap-drop ALL myapp

# Add only needed capabilities
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myapp

# Limit resources
docker run --memory=512m --cpus=0.5 myapp

# Don't run as root
docker run --user 1000:1000 myapp

# No new privileges
docker run --security-opt no-new-privileges myapp
```

### Security Checklist

| Item | Check |
|------|-------|
| Base image from trusted source | Docker Official Images |
| Image scanned for vulnerabilities | Trivy, Snyk, Grype |
| Running as non-root user | USER instruction |
| Minimal base image | Alpine, Distroless, Slim |
| No secrets in image | Environment variables, Vault |
| Read-only filesystem where possible | --read-only flag |
| Resource limits set | --memory, --cpus |
| Capabilities dropped | --cap-drop ALL |

---

## Production Considerations

### Container Logging

```bash
# View logs
docker logs mycontainer

# Log drivers (configure in daemon.json or per container)
docker run --log-driver json-file --log-opt max-size=10m myapp
docker run --log-driver syslog myapp
docker run --log-driver fluentd myapp
```

### Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

### Resource Management

```yaml
# docker-compose.yml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Restart Policies

| Policy | Behavior |
|--------|----------|
| `no` | Never restart |
| `always` | Always restart |
| `unless-stopped` | Restart unless manually stopped |
| `on-failure` | Restart only on non-zero exit |

```yaml
services:
  api:
    restart: unless-stopped
```

This comprehensive guide covers Docker from fundamentals to production use, with detailed explanations and practical examples.
