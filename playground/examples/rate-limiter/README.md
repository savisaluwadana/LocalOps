# API Rate Limiter

Distributed rate limiting service.

## Features

- **Algorithms** - Token bucket, sliding window, fixed window
- **Distributed** - Redis-backed for multi-instance
- **Per-user/IP** - Granular limits
- **Headers** - Rate limit info in responses
- **Whitelist** - Bypass for trusted IPs

## Quick Start

```bash
docker compose up -d

# Test rate limiting
for i in {1..15}; do
  curl -w "%{http_code}\n" -o /dev/null -s http://localhost:8000/api/test
done
# After 10 requests: 429 Too Many Requests
```

## Configuration

```yaml
limits:
  default:
    requests: 100
    window: 60s
  /api/auth:
    requests: 5
    window: 60s
  /api/search:
    requests: 30
    window: 60s
```
