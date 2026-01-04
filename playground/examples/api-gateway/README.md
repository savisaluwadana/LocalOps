# API Gateway with Kong

Centralized API management with authentication, rate limiting, and logging.

## Features

- **Authentication** - API keys, JWT, OAuth
- **Rate Limiting** - Protect APIs from abuse
- **Request Transformation** - Modify requests/responses
- **Load Balancing** - Distribute traffic
- **Logging** - Centralized request logs
- **Caching** - Reduce backend load

## Architecture

```
Client → Kong Gateway → Backend Services
              │
              ├─ Auth Plugin
              ├─ Rate Limit
              ├─ Logging
              └─ More...
```

## Quick Start

```bash
docker compose up -d

# Admin API: http://localhost:8001
# Gateway: http://localhost:8000

# Add a service
curl -X POST http://localhost:8001/services \
    -d name=my-api \
    -d url=http://httpbin.org

# Add a route
curl -X POST http://localhost:8001/services/my-api/routes \
    -d paths[]=/api

# Test
curl http://localhost:8000/api/get
```

## Plugins

```bash
# Rate limiting
curl -X POST http://localhost:8001/plugins \
    -d name=rate-limiting \
    -d config.minute=5

# API Key auth
curl -X POST http://localhost:8001/plugins \
    -d name=key-auth
```
