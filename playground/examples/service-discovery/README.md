# Service Discovery

Consul-based service registration and discovery.

## Features

- **Service Registration** - Auto-register on startup
- **Health Checks** - HTTP, TCP, TTL checks
- **DNS Resolution** - `service.consul` queries
- **Key-Value Store** - Configuration storage
- **Load Balancing** - Client-side LB with Fabio

## Quick Start

```bash
docker compose up -d

# Consul UI: http://localhost:8500

# Register service
curl -X PUT http://localhost:8500/v1/agent/service/register \
  -d '{"Name": "api", "Port": 8000, "Check": {"HTTP": "http://localhost:8000/health", "Interval": "10s"}}'

# Query service
curl http://localhost:8500/v1/catalog/service/api
```
