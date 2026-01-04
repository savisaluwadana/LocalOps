# Log Management Platform

Centralized logging with Elasticsearch, Loki, and OpenTelemetry Collector for log aggregation, analysis, and alerting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          LOG MANAGEMENT PLATFORM                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         LOG COLLECTION                                         │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Fluentd       │  │   Vector        │  │       Promtail                  ││  │
│  │  │   (All-purpose) │  │   (Performance) │  │       (Loki-focused)            ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         PROCESSING LAYER                                       │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    OpenTelemetry Collector                               │  │  │
│  │  │  • Log parsing       • Enrichment       • Filtering                      │  │  │
│  │  │  • Transformations   • Sampling         • Batching                       │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                                   │
│  ┌───────────────────────────────▼───────────────────────────────────────────────┐  │
│  │                         STORAGE & SEARCH                                       │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Elasticsearch │  │   Loki          │  │       ClickHouse               ││  │
│  │  │   (Full-text)   │  │   (Label-based) │  │       (Analytics)              ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         VISUALIZATION & ALERTING                               │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │   Kibana        │  │   Grafana       │  │       Alertmanager              ││  │
│  │  │   (ELK)         │  │                 │  │       (Log-based alerts)        ││  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Unified Collection** - All logs in one place
- **Structured Logging** - JSON format with context
- **Full-Text Search** - Elasticsearch for complex queries
- **Label-Based** - Loki for Prometheus-style queries
- **Retention Policies** - Automated log lifecycle
- **Alerting** - Log-based anomaly detection

## Quick Start

```bash
# Option 1: Loki Stack (lightweight)
helm install loki grafana/loki-stack --values loki-values.yaml

# Option 2: ELK Stack (full-featured)
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
helm install filebeat elastic/filebeat
```

## Log Levels

| Level | Use Case | Example |
|-------|----------|---------|
| DEBUG | Development details | "Query params: {id: 123}" |
| INFO | Normal operations | "User logged in" |
| WARN | Potential issues | "Retry attempt 2/3" |
| ERROR | Errors (non-fatal) | "Payment failed, retrying" |
| FATAL | Critical failures | "Database connection lost" |

## Structured Log Format

```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "ERROR",
  "service": "payment-service",
  "version": "v1.2.3",
  "environment": "production",
  "trace_id": "abc123",
  "span_id": "def456",
  "user_id": "user_789",
  "message": "Payment processing failed",
  "error": {
    "type": "PaymentDeclinedException",
    "message": "Card declined",
    "code": "INSUFFICIENT_FUNDS"
  },
  "context": {
    "payment_id": "pay_123",
    "amount": 99.99,
    "currency": "USD"
  }
}
```

## Retention Policies

| Environment | Hot Storage | Warm Storage | Cold/Archive |
|-------------|-------------|--------------|--------------|
| Production | 7 days | 30 days | 1 year |
| Staging | 3 days | 14 days | 90 days |
| Development | 1 day | 7 days | 30 days |

## Log Queries (Loki)

```logql
# Errors in payment service
{service="payment-service"} |= "ERROR"

# Parse JSON and filter
{service="api-gateway"} 
  | json 
  | status_code >= 500 
  | line_format "{{.method}} {{.path}} - {{.status_code}}"

# Rate of errors per minute
sum(rate({service="api-gateway"} |= "ERROR" [1m])) by (path)
```
