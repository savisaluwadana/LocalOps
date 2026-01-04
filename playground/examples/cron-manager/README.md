# Cron Job Manager

Distributed cron job scheduling and execution.

## Features

- **Cron Syntax** - Standard cron expressions
- **Distributed** - Run across multiple workers
- **Locking** - Prevent duplicate execution
- **Retries** - Configurable retry logic
- **History** - Execution history and logs
- **UI Dashboard** - Job management interface

## Quick Start

```bash
docker compose up -d

# Dashboard: http://localhost:3000

# Create job
curl -X POST http://localhost:8000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cleanup",
    "schedule": "0 * * * *",
    "command": "node cleanup.js"
  }'
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/jobs` | Create job |
| `GET /api/jobs` | List jobs |
| `POST /api/jobs/:id/trigger` | Manual trigger |
| `GET /api/jobs/:id/history` | Execution history |
