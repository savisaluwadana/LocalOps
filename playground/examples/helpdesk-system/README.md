# Helpdesk/Ticketing System

IT support and customer service ticketing.

## Features

- **Tickets** - Create, assign, resolve
- **Categories** - Categorization, priorities
- **SLA** - Response/resolution time tracking
- **Knowledge Base** - FAQ, articles
- **Agents** - Teams, workload management
- **Automation** - Auto-assign, escalation
- **Reports** - Metrics, satisfaction

## Quick Start

```bash
docker compose up -d

# Portal: http://localhost:3000
# Agent Dashboard: http://localhost:3001
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/tickets` | Create ticket |
| `PUT /api/tickets/:id/assign` | Assign ticket |
| `PUT /api/tickets/:id/resolve` | Resolve ticket |
| `GET /api/reports/sla` | SLA report |
