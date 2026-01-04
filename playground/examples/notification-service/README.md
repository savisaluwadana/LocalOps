# Notification Service

A multi-channel notification service supporting email, SMS, push, and webhooks.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       NOTIFICATION SERVICE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Applications                                                                │
│       │                                                                      │
│       │  POST /api/notifications                                             │
│       ▼                                                                      │
│  ┌─────────────────┐     ┌─────────────────┐                                │
│  │   Notification  │────►│     Redis       │                                │
│  │      API        │     │   (Queue/Rate)  │                                │
│  └─────────────────┘     └─────────────────┘                                │
│           │                                                                  │
│           │  Queue                                                           │
│           ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         WORKERS                                      │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │    │
│  │  │   Email     │  │    SMS      │  │    Push     │  │   Webhook   │ │    │
│  │  │   Worker    │  │   Worker    │  │   Worker    │  │   Worker    │ │    │
│  │  │ (Sendgrid)  │  │  (Twilio)   │  │  (Firebase) │  │   (HTTP)    │ │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-channel** - Email, SMS, push, webhooks
- **Templates** - Handlebars templates per channel
- **Rate Limiting** - Per user, per channel limits
- **Retry Logic** - Exponential backoff
- **Batching** - Aggregate notifications
- **Preferences** - User notification settings
- **Analytics** - Open rates, delivery stats

## Quick Start

```bash
docker compose up -d

# Send notification
curl -X POST http://localhost:8000/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "123",
    "channels": ["email", "push"],
    "template": "welcome",
    "data": {"name": "John"}
  }'
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/notifications` | Send notification |
| `GET /api/notifications/:id` | Get status |
| `POST /api/templates` | Create template |
| `PUT /api/preferences/:userId` | Update preferences |
