# SSL Certificate Manager

Automated SSL certificate management with Let's Encrypt.

## Features

- **Auto-renewal** - Automatic certificate renewal
- **ACME Support** - Let's Encrypt integration
- **Wildcard Certs** - DNS challenge support
- **Multiple Domains** - Manage many certs
- **Expiry Alerts** - Notifications before expiry

## Quick Start

```bash
docker compose up -d

# Request certificate
curl -X POST http://localhost:8000/api/certificates \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com", "email": "admin@example.com"}'

# List certificates
curl http://localhost:8000/api/certificates
```
