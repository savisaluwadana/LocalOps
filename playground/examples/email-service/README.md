# Email Service

A transactional email service with templates and analytics.

## Features

- **Templates** - MJML/Handlebars templates
- **Providers** - Sendgrid, SES, Mailgun
- **Queuing** - Async delivery with retries
- **Analytics** - Opens, clicks, bounces
- **Attachments** - File support
- **Webhooks** - Delivery status callbacks

## Quick Start

```bash
docker compose up -d

curl -X POST http://localhost:8000/api/email/send \
  -H "Content-Type: application/json" \
  -d '{
    "to": "user@example.com",
    "template": "welcome",
    "data": {"name": "John"}
  }'

# View emails: http://localhost:8025
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/email/send` | Send email |
| `POST /api/templates` | Create template |
| `GET /api/email/:id/status` | Get delivery status |
