# Task Queue System

A distributed task queue for background job processing.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TASK QUEUE SYSTEM                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Producer (API)                                                              │
│       │                                                                      │
│       │  enqueue(task)                                                       │
│       ▼                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                          REDIS QUEUE                                 │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │   Pending   │  │  Processing │  │   Completed │                  │    │
│  │  │    Queue    │  │    Queue    │  │    Queue    │                  │    │
│  │  └──────┬──────┘  └─────────────┘  └─────────────┘                  │    │
│  │         │                                                            │    │
│  └─────────┼────────────────────────────────────────────────────────────┘    │
│            │                                                                  │
│            │  dequeue()                                                       │
│            ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                          WORKERS                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │  Worker 1   │  │  Worker 2   │  │  Worker 3   │                  │    │
│  │  │ (email)     │  │ (image)     │  │ (export)    │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multiple Queues** - Priority, scheduled, delayed
- **Retries** - Exponential backoff, dead letter
- **Concurrency** - Configurable workers per queue
- **Scheduling** - Cron-like job scheduling
- **Dashboard** - Real-time monitoring (Bull Board)
- **Rate Limiting** - Prevent overwhelming APIs

## Quick Start

```bash
docker compose up -d

# Access dashboard
open http://localhost:3000/admin/queues

# Enqueue a job
curl -X POST http://localhost:8000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{"type": "email", "data": {"to": "user@example.com", "subject": "Hello"}}'
```

## Job Types

| Type | Description |
|------|-------------|
| `email` | Send emails |
| `image-resize` | Process images |
| `export` | Generate reports/exports |
| `webhook` | Call external webhooks |
| `cleanup` | Data cleanup tasks |
