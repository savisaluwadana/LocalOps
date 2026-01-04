# URL Shortener Service

A scalable URL shortening service with analytics and rate limiting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         URL SHORTENER SERVICE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  User Request: https://short.ly/abc123                                       │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────┐  Rate Limit  ┌─────────────────┐                       │
│  │  Load Balancer  │─────────────►│     Redis       │                       │
│  │    (nginx)      │              │    (Cache)      │                       │
│  └────────┬────────┘              └─────────────────┘                       │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐              ┌─────────────────┐                       │
│  │   API Server    │◄────────────►│   PostgreSQL    │                       │
│  │   (Node.js)     │              │   (Storage)     │                       │
│  └────────┬────────┘              └─────────────────┘                       │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐              ┌─────────────────┐                       │
│  │  Click Stream   │─────────────►│    ClickHouse   │                       │
│  │   (RabbitMQ)    │              │   (Analytics)   │                       │
│  └─────────────────┘              └─────────────────┘                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Base62 Encoding** - Short, URL-safe codes
- **Custom Aliases** - User-defined short codes
- **Analytics** - Click tracking, geo, referrer
- **Rate Limiting** - Prevent abuse
- **Expiration** - Time-limited links
- **QR Codes** - Generate QR for any link

## Quick Start

```bash
docker compose up -d

# Shorten a URL
curl -X POST http://localhost:8000/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/very/long/url"}'

# Visit: http://localhost:8000/abc123
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/shorten` | Create short URL |
| `GET /:code` | Redirect to original URL |
| `GET /api/stats/:code` | Get click statistics |
| `DELETE /api/urls/:code` | Delete short URL |
