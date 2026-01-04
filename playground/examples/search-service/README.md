# Search Service

Full-text search with Elasticsearch.

## Features

- **Full-text Search** - Fuzzy matching, highlighting
- **Faceted Search** - Filters, aggregations
- **Autocomplete** - Suggestions as you type
- **Indexing** - Real-time sync from DB
- **Multi-tenant** - Per-tenant indices

## Quick Start

```bash
docker compose up -d

# Index document
curl -X POST http://localhost:8000/api/index/products \
  -H "Content-Type: application/json" \
  -d '{"id": "1", "name": "Laptop", "description": "Gaming laptop"}'

# Search
curl "http://localhost:8000/api/search?q=laptop&index=products"

# Kibana: http://localhost:5601
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/index/:index` | Index document |
| `GET /api/search` | Search documents |
| `GET /api/suggest` | Autocomplete |
| `DELETE /api/index/:index/:id` | Delete document |
