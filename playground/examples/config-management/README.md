# Configuration Management Service

Centralized configuration for distributed systems.

## Features

- **Dynamic Config** - Hot reload without restart
- **Versioning** - Config version history
- **Environments** - Dev/staging/production configs
- **Encryption** - Secrets encrypted at rest
- **Audit Trail** - Track all changes
- **Watch API** - Real-time updates

## Quick Start

```bash
docker compose up -d

# Create config
curl -X POST http://localhost:8000/api/configs \
  -H "Content-Type: application/json" \
  -d '{"key": "database.url", "value": "postgres://...", "env": "production"}'

# Get config
curl http://localhost:8000/api/configs/database.url?env=production

# Watch for changes
curl -N http://localhost:8000/api/configs/watch?key=database.url
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/configs` | Create/update config |
| `GET /api/configs/:key` | Get config value |
| `GET /api/configs/watch` | SSE for real-time updates |
| `GET /api/configs/history/:key` | Get version history |
