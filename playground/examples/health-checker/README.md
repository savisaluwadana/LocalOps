# Health Check Service

Uptime monitoring and health checks for services.

## Features

- **HTTP/TCP Checks** - Monitor any endpoint
- **Intervals** - Configurable check frequency
- **Status Pages** - Public status page
- **Incidents** - Track downtime incidents
- **Notifications** - Slack, email, SMS, PagerDuty
- **Metrics** - Latency, uptime percentage

## Quick Start

```bash
docker compose up -d

# Status page: http://localhost:3000
# API: http://localhost:8000

# Add monitor
curl -X POST http://localhost:8000/api/monitors \
  -H "Content-Type: application/json" \
  -d '{"name": "API", "url": "https://api.example.com/health", "interval": 60}'

# Get status
curl http://localhost:8000/api/status
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/monitors` | Create monitor |
| `GET /api/monitors` | List monitors |
| `GET /api/status` | Current status |
| `GET /api/incidents` | List incidents |
