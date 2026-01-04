# CRM System

Customer Relationship Management platform.

## Features

- **Contacts** - Customer profiles, companies
- **Deals/Pipeline** - Sales stages, forecasting
- **Activities** - Calls, emails, meetings
- **Tasks** - Follow-ups, reminders
- **Reports** - Sales analytics, performance
- **Email Integration** - Track conversations
- **Custom Fields** - Flexible data model

## Quick Start

```bash
docker compose up -d

# CRM: http://localhost:3000
# API: http://localhost:8000
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/contacts` | List contacts |
| `GET /api/deals` | List deals |
| `POST /api/deals/:id/stage` | Update deal stage |
| `GET /api/reports/pipeline` | Pipeline report |
