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

### Network Types

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           DOCKER NETWORK TYPES                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   BRIDGE (default)                                                                   │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │                    Docker Bridge Network                     │                   │
│   │                    (172.17.0.0/16)                          │                   │
│   │     ┌────────┐         ┌────────┐         ┌────────┐       │                   │
│   │     │ nginx  │         │  api   │         │  db    │       │                   │
│   │     │.17.0.2 │────────▶│.17.0.3 │────────▶│.17.0.4 │       │                   │
│   │     └───┬────┘         └────────┘         └────────┘       │                   │
│   └─────────┼─────────────────────────────────────────────────────┘                   │
│             │ Port mapping (e.g., 8080:80)                                          │
│             ▼                                                                        │
│   ┌─────────────────┐                                                               │
│   │    Host Network │                                                               │
│   │   (your machine)│                                                               │
│   └─────────────────┘                                                               │
│                                                                                      │
│   HOST (no isolation)                                                               │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │    Container uses host's network directly                   │                   │
│   │    No port mapping needed - binds to host ports directly   │                   │
│   │    Best performance, but no network isolation               │                   │
│   └─────────────────────────────────────────────────────────────┘                   │
│                                                                                      │
│   NONE (no networking)                                                              │
│   ┌─────────────────────────────────────────────────────────────┐                   │
│   │    Container has no network access                          │                   │
│   │    Only loopback (127.0.0.1)                                │                   │
│   │    Maximum isolation                                        │                   │
│   └─────────────────────────────────────────────────────────────┘                   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Network Commands

```bash
# List networks
docker network ls

# Create a custom network
docker network create myapp-network

# Create with specific settings
docker network create \
    --driver bridge \
    --subnet 192.168.1.0/24 \
    --gateway 192.168.1.1 \
    myapp-network

# Connect container to network
docker network connect myapp-network my-container

# Disconnect container from network
docker network disconnect myapp-network my-container

# Inspect network
docker network inspect myapp-network

# Remove network
docker network rm myapp-network
```

### Container DNS

On user-defined networks, containers can reach each other by name:

```bash
# Create network
docker network create myapp

# Run containers on same network
docker run -d --name api --network myapp myapi
docker run -d --name db --network myapp postgres

# Now 'api' can reach 'db' by name:
# In api container: psql -h db -U postgres
# Docker's built-in DNS resolves 'db' → container IP
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
